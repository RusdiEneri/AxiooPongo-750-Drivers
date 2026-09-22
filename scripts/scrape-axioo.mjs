import fs from "node:fs/promises";

const BASE_URL = "https://driver.axiooworld.com";

const SERIES_REFF = "13";
const TARGET_MODEL = "750";
const TARGET_VENDOR_CODE = "NP50RNC1";

const OUTPUT_DIR = new URL("../generated/", import.meta.url);
const SPECIAL_FILE = new URL("../config/special-drivers.json", import.meta.url);

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      accept: "application/json, text/javascript, */*; q=0.01",
      "accept-language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7",
      "x-requested-with": "XMLHttpRequest",
      referer: `${BASE_URL}/`,
      ...(options.headers || {})
    }
  });

  if (!response.ok) {
    throw new Error(
      `HTTP ${response.status} ${response.statusText} - ${url}`
    );
  }

  const text = await response.text();

  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`Response bukan JSON valid dari: ${url}`);
  }
}

function normalizeVersion(description = "") {
  const match = description.match(/Version\s*:\s*([^,]+)/i);
  return match ? match[1].trim() : null;
}

function deriveFriendlyName(item) {
  if (!item.description) return item.title || "Driver";
  const parts = item.description.split(/,\s*Version\s*:/i);
  if (parts.length > 1 && parts[0].trim().length > 0) {
    return parts[0].trim();
  }
  return item.title || item.description;
}

function deriveInstallType(item) {
  const file = (item.file_repo || "").toLowerCase();
  if (file.includes("hidfilter") || file.includes("hid_filter")) {
    return {
      type: "inf",
      inf: "HidEventFilter.inf"
    };
  }
  if (file.includes("chipset_intel") || file.includes("speedshift") || file.includes("gna_")) {
    return {
      type: "inf"
    };
  }
  return {
    type: "package"
  };
}

function normalizeDriver(item) {
  const titleSlug = String(item.title || "driver")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

  return {
    id: `${titleSlug}-${item.repo_id}`,

    repo_id: item.repo_id,
    date: item.date,
    year: item.year,
    author: item.author || "RND",

    title: item.title,
    category: item.title,
    name: deriveFriendlyName(item),
    description: item.description,
    version: normalizeVersion(item.description),

    series: item.series,
    model: item.model,
    vendor_code: item.vendor_code,

    template_name: item.template_name,

    folder_repo: item.folder_repo,
    file_repo: item.file_repo,
    download_url: item.download_url,
    download_size: item.download_size,

    source: "axioo",
    install: deriveInstallType(item)
  };
}

async function main() {
  console.log("=== Axioo Pongo 750 Driver Scraper ===");
  console.log(`Target: Model ${TARGET_MODEL} / Vendor Code ${TARGET_VENDOR_CODE}`);

  // ------------------------------------------------------------
  // 1. Get models
  // ------------------------------------------------------------
  console.log("\n[1/3] Mengambil daftar model PONGO...");
  const modelsUrl =
    `${BASE_URL}/fetch/get_models?reff=${encodeURIComponent(SERIES_REFF)}`;

  const modelsResponse = await fetchJson(modelsUrl);

  if (modelsResponse.status !== "success" || !Array.isArray(modelsResponse.data)) {
    throw new Error("get_models mengembalikan format atau status invalid");
  }

  const model = modelsResponse.data.find(
    item => item.model_name === TARGET_MODEL
  );

  if (!model) {
    throw new Error(
      `Model ${TARGET_MODEL} tidak ditemukan untuk series ${SERIES_REFF}`
    );
  }

  console.log(`  Model       : ${model.model_name}`);
  console.log(`  Model Reff  : ${model.id}`);
  console.log(`  Series Reff : ${SERIES_REFF}`);

  // ------------------------------------------------------------
  // 2. Get template
  // ------------------------------------------------------------
  console.log("\n[2/3] Mengambil template produk...");
  const templateUrl =
    `${BASE_URL}/fetch/get_template_item` +
    `?series_reff=${encodeURIComponent(SERIES_REFF)}` +
    `&model_reff=${encodeURIComponent(model.id)}` +
    `&group_by=true`;

  const templateResponse = await fetchJson(templateUrl);

  if (templateResponse.status !== "success" || !Array.isArray(templateResponse.data)) {
    throw new Error("get_template_item mengembalikan format atau status invalid");
  }

  const template = templateResponse.data.find(
    item => item.vendor_code === TARGET_VENDOR_CODE
  );

  if (!template) {
    throw new Error(
      `Vendor code ${TARGET_VENDOR_CODE} tidak ditemukan pada model ${TARGET_MODEL}`
    );
  }

  console.log(`  Template ID  : ${template.template_id}`);
  console.log(`  Vendor Code  : ${template.vendor_code}`);
  console.log(`  Template     : ${template.template_name}`);
  console.log(`  Item Code    : ${template.item_code}`);

  // ------------------------------------------------------------
  // 3. Get driver list
  // ------------------------------------------------------------
  console.log("\n[3/3] Mengambil daftar driver resmi...");
  const form = new FormData();
  form.append("series", SERIES_REFF);
  form.append("model", model.id);
  form.append("template", TARGET_VENDOR_CODE);

  const driverUrl = `${BASE_URL}/fetch/get_driver_list_by_product`;

  const driverResponse = await fetchJson(driverUrl, {
    method: "POST",
    body: form
  });

  if (driverResponse.status !== "success" || !Array.isArray(driverResponse.data)) {
    throw new Error("get_driver_list_by_product mengembalikan format atau status invalid");
  }

  console.log(`  Jumlah driver resmi: ${driverResponse.data.length}`);

  // ------------------------------------------------------------
  // 4. Normalize drivers
  // ------------------------------------------------------------
  const drivers = driverResponse.data.map(normalizeDriver);

  // ------------------------------------------------------------
  // 5. Load special drivers (Intel Serial IO, etc.)
  // ------------------------------------------------------------
  let special = {};

  try {
    const rawSpecial = await fs.readFile(SPECIAL_FILE, "utf8");
    special = JSON.parse(rawSpecial);
    console.log(`  Special drivers loaded: ${Object.keys(special).join(", ")}`);
  } catch (err) {
    console.warn("  [WARN] Tidak dapat memuat special-drivers.json:", err.message);
  }

  // ------------------------------------------------------------
  // 6. Generate drivers.json
  // ------------------------------------------------------------
  const generated = {
    generated_at: new Date().toISOString(),

    model: {
      brand: "Axioo",
      series: "PONGO",
      model: TARGET_MODEL,
      code: TARGET_VENDOR_CODE,
      series_reff: SERIES_REFF,
      model_reff: String(model.id),
      target_os: "Windows 11 x64"
    },

    template: {
      id: String(template.template_id),
      name: template.template_name,
      item_code: template.item_code
    },

    source: {
      website: BASE_URL,
      models_endpoint: "/fetch/get_models",
      template_endpoint: "/fetch/get_template_item",
      driver_endpoint: "/fetch/get_driver_list_by_product"
    },

    drivers,
    special
  };

  await fs.mkdir(OUTPUT_DIR, { recursive: true });

  await fs.writeFile(
    new URL("drivers.json", OUTPUT_DIR),
    JSON.stringify(generated, null, 2) + "\n"
  );

  // ------------------------------------------------------------
  // 7. Generate version.json
  // ------------------------------------------------------------
  const versions = {};

  for (const driver of drivers) {
    versions[driver.id] = {
      category: driver.category,
      name: driver.name,
      version: driver.version,
      date: driver.date,
      repo_id: driver.repo_id,
      file: driver.file_repo,
      url: driver.download_url
    };
  }

  for (const [key, driver] of Object.entries(special)) {
    versions[key] = {
      category: driver.category,
      name: driver.name,
      version: driver.version,
      source: driver.source,
      url: driver.url
    };
  }

  const versionData = {
    generated_at: new Date().toISOString(),
    model: "Axioo Pongo 750",
    vendor_code: TARGET_VENDOR_CODE,
    target_os: "Windows 11 x64",
    versions
  };

  await fs.writeFile(
    new URL("version.json", OUTPUT_DIR),
    JSON.stringify(versionData, null, 2) + "\n"
  );

  console.log("\nMetadata berhasil diperbarui:");
  console.log("  - generated/drivers.json");
  console.log("  - generated/version.json");
}

main().catch(error => {
  console.error("\n[ERROR] SCRAPER GAGAL:");
  console.error(error);
  process.exit(1);
});