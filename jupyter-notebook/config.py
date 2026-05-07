from __future__ import annotations
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from mrct.core.exceptions import MRCTInputError


@dataclass
class MRCTConfig:
    # --- Rutas ---
    root: Path
    basin_raster: Path
    anthropic_raster: Path
    basin_shp: Path
    mosaics_root: Path
    output_folder: Path
    scenario_anthropic_raster: Optional[Path] = None

    # --- Años ---
    years: list = field(default_factory=lambda: list(range(2013, 2026)))
    baseline_years: list = field(
        default_factory=lambda: [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022]
    )

    # --- Umbrales temáticos ---
    thresh_veg: float = 0.2
    thresh_water: float = 0.2
    thresh_soil: float = 0.1
    thresh_snow: float = 0.4
    thresh_wetland: float = 0.1
    thresh_anthropic: float = 0.2

    # --- Conectividad de parches ---
    connectivity: int = 8

    # --- Dominio ---
    domain_metric: str = "mahalanobis"
    domain_bandwidth_q: float = 0.90
    domain_c: float = 2.5

    # --- Ponderaciones PT (antes variables globales sueltas) ---
    alpha: float = 1.0
    beta_local: float = 0.5

    # --- Parámetros prospectivos ---
    frag_alpha: float = 0.6
    spillover: float = 0.3

    # --- Métricas de paisaje ---
    lpi_enabled: bool = True

    # --- KNN vecindad ---
    knn_k: int = 8

    def __post_init__(self) -> None:
        self.root = Path(self.root)
        self.basin_raster = Path(self.basin_raster)
        self.anthropic_raster = Path(self.anthropic_raster)
        self.basin_shp = Path(self.basin_shp)
        self.mosaics_root = Path(self.mosaics_root)
        self.output_folder = Path(self.output_folder)
        if self.scenario_anthropic_raster is not None:
            self.scenario_anthropic_raster = Path(self.scenario_anthropic_raster)

    @classmethod
    def from_dict(cls, d: dict) -> "MRCTConfig":
        """Construye desde un dict estilo CONFIG original + rutas explícitas."""
        return cls(
            root=d["root"],
            basin_raster=d["basin_raster"],
            anthropic_raster=d["anthropic_raster"],
            basin_shp=d["basin_shp"],
            mosaics_root=d["mosaics_root"],
            output_folder=d["output_folder"],
            scenario_anthropic_raster=d.get("scenario_anthropic_raster"),
            years=d.get("YEARS", list(range(2013, 2026))),
            baseline_years=d.get("BASELINE_YEARS", [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022]),
            thresh_veg=d.get("THRESH_VEG", 0.2),
            thresh_water=d.get("THRESH_WATER", 0.2),
            thresh_soil=d.get("THRESH_SOIL", 0.1),
            thresh_snow=d.get("THRESH_SNOW", 0.4),
            thresh_wetland=d.get("THRESH_WETLAND", 0.1),
            thresh_anthropic=d.get("THRESH_ANTHROPIC", 0.2),
            connectivity=d.get("CONNECTIVITY", 8),
            domain_metric=d.get("DOMAIN_METRIC", "mahalanobis"),
            domain_bandwidth_q=d.get("DOMAIN_BANDWIDTH_Q", 0.90),
            domain_c=d.get("DOMAIN_C", 2.5),
            alpha=d.get("alpha", 1.0),
            beta_local=d.get("beta_local", 0.5),
            frag_alpha=d.get("FRAG_ALPHA", 0.6),
            spillover=d.get("SPILLOVER", 0.3),
            lpi_enabled=d.get("FRAG_METRICS", {}).get("LPI", True),
            knn_k=d.get("knn_k", 8),
        )

    def validate(self) -> None:
        for p in [self.basin_raster, self.anthropic_raster, self.basin_shp]:
            if not p.exists():
                raise MRCTInputError(f"No se encuentra el insumo crítico: {p}")
