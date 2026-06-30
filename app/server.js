"use strict";

/**
 * Cloud DevOps - Image storage application (Part II)
 *
 * Authentication model:
 *   The app NEVER holds storage keys or connection strings. It authenticates to
 *   both Azure Storage and Key Vault with a User-Assigned Managed Identity via
 *   DefaultAzureCredential. The identity's client id is provided through the
 *   AZURE_CLIENT_ID app setting (set by Terraform).
 *
 * Pages:
 *   GET  /               Web Page 1 - lists all blobs with a download link each,
 *                        plus a link to Web Page 2.
 *   GET  /upload         Web Page 2 - upload form.
 *   POST /upload         Receives the file and stores it as a blob.
 *   GET  /download/:name Streams a blob back to the browser as a download.
 *   GET  /healthz        Liveness probe.
 */

const path = require("path");
const express = require("express");
const multer = require("multer");
const { DefaultAzureCredential } = require("@azure/identity");
const { BlobServiceClient } = require("@azure/storage-blob");
const { SecretClient } = require("@azure/keyvault-secrets");

// --- Configuration (from App Service settings) ------------------------------
const PORT = process.env.PORT || 3000;
const STORAGE_ACCOUNT_NAME = process.env.STORAGE_ACCOUNT_NAME;
const CONTAINER_NAME = process.env.BLOB_CONTAINER || "images";
const KEY_VAULT_NAME = process.env.KEY_VAULT_NAME;
const MANAGED_IDENTITY_CLIENT_ID = process.env.AZURE_CLIENT_ID;

if (!STORAGE_ACCOUNT_NAME) {
  console.error("FATAL: STORAGE_ACCOUNT_NAME is not set.");
  process.exit(1);
}

// One credential shared by every Azure SDK client. On App Service it resolves
// to the user-assigned managed identity; locally it falls back to az login.
const credential = new DefaultAzureCredential(
  MANAGED_IDENTITY_CLIENT_ID
    ? { managedIdentityClientId: MANAGED_IDENTITY_CLIENT_ID }
    : undefined
);

// --- Azure clients ----------------------------------------------------------
const blobServiceClient = new BlobServiceClient(
  `https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
  credential
);
const containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);

const secretClient = KEY_VAULT_NAME
  ? new SecretClient(`https://${KEY_VAULT_NAME}.vault.azure.net`, credential)
  : null;

/**
 * Reads the sensitive welcome message from Key Vault. Failures are non-fatal so
 * the app still serves pages if the secret/vault is unavailable.
 */
async function getWelcomeMessage() {
  if (!secretClient) return null;
  try {
    const secret = await secretClient.getSecret("app-welcome-message");
    return secret.value;
  } catch (err) {
    console.warn(`Could not read Key Vault secret: ${err.message}`);
    return null;
  }
}

// --- Express setup ----------------------------------------------------------
const app = express();
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Files are kept in memory and streamed straight to blob storage.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB
});

// Web Page 1: list every blob with a download link + link to Web Page 2.
app.get("/", async (req, res, next) => {
  try {
    const blobs = [];
    for await (const blob of containerClient.listBlobsFlat()) {
      blobs.push({
        name: blob.name,
        size: blob.properties.contentLength,
        lastModified: blob.properties.lastModified,
      });
    }
    const welcomeMessage = await getWelcomeMessage();
    res.render("index", { blobs, welcomeMessage });
  } catch (err) {
    next(err);
  }
});

// Web Page 2: the upload form.
app.get("/upload", (req, res) => {
  res.render("upload", { error: null });
});

// Handle the uploaded file -> store it as a blob, then back to Web Page 1.
app.post("/upload", upload.single("file"), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).render("upload", { error: "Please choose a file." });
    }
    const blobName = `${Date.now()}-${req.file.originalname}`;
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    await blockBlobClient.uploadData(req.file.buffer, {
      blobHTTPHeaders: { blobContentType: req.file.mimetype },
    });
    res.redirect("/");
  } catch (err) {
    next(err);
  }
});

// Stream a blob back as a download (works with RBAC, no account key needed).
app.get("/download/:name", async (req, res, next) => {
  try {
    const blobClient = containerClient.getBlobClient(req.params.name);
    const exists = await blobClient.exists();
    if (!exists) {
      return res.status(404).send("File not found.");
    }
    const download = await blobClient.download();
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${path.basename(req.params.name)}"`
    );
    if (download.contentType) {
      res.setHeader("Content-Type", download.contentType);
    }
    download.readableStreamBody.pipe(res);
  } catch (err) {
    next(err);
  }
});

app.get("/healthz", (req, res) => res.json({ status: "ok" }));

// Central error handler.
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).send(`Error: ${err.message}`);
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
  console.log(`Storage account: ${STORAGE_ACCOUNT_NAME}, container: ${CONTAINER_NAME}`);
});
