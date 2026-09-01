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
      accept: "*/*",
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

function normalizeDriver(item) {
  return {
    id: `${String(item.title || "driver")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")}-${item.repo_id}`,

    repo_id: item.repo_id,
    date: item.date,
    year: item.year,

    category: item.title,
    name: item.description || item.title,
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

    install: {
      type: "package"
    }
  };
}

async function main() {
  console.log("=== Axioo Pongo 750 Driver Scraper ===");

  // ------------------------------------------------------------
  // 1. Get models
  // ------------------------------------------------------------

  const modelsUrl =
    `${BASE_URL}/fetch/get_models?reff=${encodeURIComponent(SERIES_REFF)}`;

  const modelsResponse = await fetchJson(modelsUrl);

  if (modelsResponse.status !== "success") {
    throw new Error("get_models mengembalikan status bukan success");
  }

  const model = modelsResponse.data.find(
    item => item.model_name === TARGET_MODEL
  );

  if (!model) {
    throw new Error(
      `Model ${TARGET_MODEL} tidak ditemukan untuk series ${SERIES_REFF}`
    );
  }

  console.log(`Model       : ${model.model_name}`);
  console.log(`Model Reff  : ${model.id}`);

  // ------------------------------------------------------------
  // 2. Get template
  // ------------------------------------------------------------

  const templateUrl =
    `${BASE_URL}/fetch/get_template_item` +
    `?series_reff=${encodeURIComponent(SERIES_REFF)}` +
    `&model_reff=${encodeURIComponent(model.id)}` +
    `&group_by=true`;

  const templateResponse = await fetchJson(templateUrl);

  if (templateResponse.status !== "success") {
    throw new Error("get_template_item gagal");
  }

  const template = templateResponse.data.find(
    item => item.vendor_code === TARGET_VENDOR_CODE
  );

  if (!template) {
    throw new Error(
      `Vendor code ${TARGET_VENDOR_CODE} tidak ditemukan`
    );
  }

  console.log(`Template ID  : ${template.template_id}`);
  console.log(`Vendor Code  : ${template.vendor_code}`);
  console.log(`Template     : ${template.template_name}`);

  // ------------------------------------------------------------
  // 3. Get driver list
  // ------------------------------------------------------------

  const form = new FormData();

  form.append("series", SERIES_REFF);
  form.append("model", model.id);
  form.append("template", TARGET_VENDOR_CODE);

  const driverUrl =
    `${BASE_URL}/fetch/get_driver_list_by_product`;

  const driverResponse = await fetchJson(driverUrl, {
    method: "POST",
    body: form
  });

  if (driverResponse.status !== "success") {
    throw new Error("get_driver_list_by_product gagal");
  }

  if (!Array.isArray(driverResponse.data)) {
    throw new Error("Data driver bukan array");
  }

  console.log(`Driver ditemukan: ${driverResponse.data.length}`);

  // ------------------------------------------------------------
  // 4. Normalize drivers
  // ------------------------------------------------------------

  const drivers = driverResponse.data.map(normalizeDriver);

  // ------------------------------------------------------------
  // 5. Load special drivers
  // ------------------------------------------------------------

  let special = {};

  try {
    special = JSON.parse(
      await fs.readFile(SPECIAL_FILE, "utf8")
    );
  } catch {
    console.log("Tidak ada special-drivers.json");
  }

  // ------------------------------------------------------------
  // 6. Generated drivers.json
  // ------------------------------------------------------------

  const generated = {
    generated_at: new Date().toISOString(),

    model: {
      brand: "Axioo",
      series: "PONGO",
      model: TARGET_MODEL,
      code: TARGET_VENDOR_CODE,
      series_reff: SERIES_REFF,
      model_reff: model.id
    },

    template: {
      id: template.template_id,
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

  await fs.mkdir(OUTPUT_DIR, {
    recursive: true
  });

  await fs.writeFile(
    new URL("drivers.json", OUTPUT_DIR),
    JSON.stringify(generated, null, 2) + "\n"
  );

  // ------------------------------------------------------------
  // 7. Generated version.json
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

    versions
  };

  await fs.writeFile(
    new URL("version.json", OUTPUT_DIR),
    JSON.stringify(versionData, null, 2) + "\n"
  );

  console.log("");
  console.log("Generated:");
  console.log("  generated/drivers.json");
  console.log("  generated/version.json");
}

main().catch(error => {
  console.error("");
  console.error("SCRAPER FAILED");
  console.error(error);
  process.exit(1);
});