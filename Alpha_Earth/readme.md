# AlphaEarth Embeddings Export — README

Pipeline to export **AlphaEarth annual embeddings + label band** for labeled polygons, with request-payload safeguards, class stats, and Drive/GCS export.

---

## 1) Prerequisites

- Python 3.9–3.11  
- Google Earth Engine account activated for the email you’ll use  
- System libs for Geo stack (GDAL/GEOS/PROJ) if installing on a fresh Linux/macOS  

**On Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y gdal-bin libgdal-dev
```

**On macOS with Homebrew:**
```bash
brew install gdal
```

If `fiona` / `rasterio` fail to build wheels, install matching GDAL or use prebuilt wheels:
```bash
pip install rasterio==<prebuilt version>
```

---

## 2) Install Python packages

In terminal (not in Python):
```bash
python -m pip install --upgrade pip
pip install earthengine-api geopandas shapely fiona rasterio matplotlib numpy pandas
```

Optional but recommended:
```bash
pip install pyproj
```

---

## 3) Authenticate Earth Engine

**In Python (script or notebook):**
```python
import ee
ee.Authenticate()   # follows browser flow
ee.Initialize()
```

If in Jupyter and the popup fails:
```python
ee.Authenticate(auth_mode='notebook')
ee.Initialize()
```

---

## 4) Save the script

Save your provided code as **export_alphaearth.py** (or use it in a notebook).  
The script expects a zipped shapefile and remaps your class field to integer IDs.

---

## 5) Configure

Edit the **CONFIG** section at the top of the script:

```python
BASENAME            = "my_training_polys"
LABEL_FIELD         = "COD_TV"
YEAR                = 2024
EXPORT_TO           = "Drive"
GCS_BUCKET          = None
FILE_PREFIX         = f"alphaearth_embeddings_{YEAR}"

SRC_METRIC_EPSG     = 25830
SIMPLIFY_TOL_M      = 8.0
BUFFER_M            = 0.0

PAD_METERS          = 0.0
MAX_EXPORTS         = 500
EXPORT_SCALE        = 10
FILE_DIM_MAX        = 8192
MAX_FILESIZE_BYTES  = 17_000_000_000
BYTES_PER_SAMPLE    = 4
MAX_PIXELS_ALLOWED  = 1e13

MIN_POLY_AREA_M2    = 10_000.0
MIN_SQUARE_AREA_M2  = 10_000.0

RECT_WGS            = None
RUN_EXPORTS         = True
ALLOW_COD_TV        = []
```

Notes:  
- BASENAME must match a `.zip` somewhere under your repo/workdir.  
- LABEL_FIELD is mapped to integers 1..N (0 reserved for background).  
- A JSON label map is written: BASENAME_label_map.json.  
- SRC_METRIC_EPSG must be meter-based CRS.  
- EXPORT_SCALE must align with model’s pixel assumption.  
- RECT_WGS can be set to pre-clip AOI:  

```python
from shapely.geometry import box
RECT_WGS = box(minx, miny, maxx, maxy)  # lon/lat in EPSG:4326
```

---

## 6) What the script does

- Init EE and logging  
- Locate/extract shapefile with GeoPandas  
- Clean/filter polygons  
- Map labels to IDs & save JSON  
- Build enclosing squares per polygon  
- Stratified sampling to MAX_EXPORTS  
- Build embeddings image from GOOGLE/SATELLITE_EMBEDDING/V1/ANNUAL  
- Compute safe fileDimensions  
- Simplify geometries if needed  
- Rasterize labels, compute stats/histogram  
- Export to Drive/GCS  

---

## 7) Running

**Script:**
```bash
python export_alphaearth.py
```

**Notebook:** paste cells, set config, run.

Logs highlight shapefile path, features kept, label map path, class mix, fileDimensions, stats table, and export started lines.

---

## 8) Outputs

- BASENAME_label_map.json  
- Drive/GCS tasks:

**Drive:**  
`alphaearth_embeddings_2024_sq_001_cls7.tif` under Drive folder (or root if None).  

**GCS:**  
`gs://<GCS_BUCKET>/<prefix>/`

Each GeoTIFF includes:  
- 64 embedding bands (float32)  
- label band (float32, 0=background, 1..N=classes)  

---

## 9) Troubleshooting

- Missing zip → ensure correct path/name  
- Label field missing → confirm column name  
- CRS wrong → set proper metric CRS  
- Payload >10 MB → increase simplify tolerance or clip AOI  
- Export too large → coarser scale, reduce padding, lower filesize  
- Auth errors → check permissions  
- Notebook auth hang → use `auth_mode='notebook'`  

---

## 10) Parameter guidance

- MIN_POLY_AREA_M2 / MIN_SQUARE_AREA_M2 ~100 px at 10 m scale  
- FILE_DIM_MAX capped by bytes/bands  
- BALANCE_TILES / MIN_PER_CLASS avoids imbalance  
- PAD_METERS adds context  

---

## 11) Example minimal config

```python
BASENAME        = "training_polys_asturias"
LABEL_FIELD     = "COD_TV"
YEAR            = 2024
EXPORT_TO       = "Drive"
GCS_BUCKET      = None
SRC_METRIC_EPSG = 25830
SIMPLIFY_TOL_M  = 8.0
RUN_EXPORTS     = True
ALLOW_COD_TV    = []
```

---

## 12) Data source

Embeddings: GOOGLE/SATELLITE_EMBEDDING/V1/ANNUAL  
Filtered by year, mosaicked, float32.

---

## 13) Limitations

- Heuristic safeguards, edge cases can fail  
- Label rasterization uses integer IDs → keep JSON  

---

## 14) License & attribution

Comply with Google Earth Engine and dataset terms.
