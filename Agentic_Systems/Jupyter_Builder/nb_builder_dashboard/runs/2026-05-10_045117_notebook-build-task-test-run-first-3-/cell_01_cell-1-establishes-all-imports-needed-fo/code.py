# ── Cell 1: All imports ───────────────────────────────────────────────────────
from arcgis.gis import GIS
from arcgis.features import FeatureLayer, FeatureSet, Feature
from arcgis.geometry import Point, Polygon, Geometry
import pandas as pd
import json
import os
import urllib.request
import urllib.parse

print("✅ Imports complete")