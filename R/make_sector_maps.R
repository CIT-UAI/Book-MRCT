library(dplyr)
library(sf)
library(mapview)
library(htmlwidgets)

# Configuracion -----------------------------------------------------------

path_cuencas <- "data/cuencas_seleccionadas/cuencas_seleccionadas_v1.shp"
path_accesos <- "data/cuencas_seleccionadas/accesos_cuencas_v1.shp"
path_out <- "data/maps"

dir.create(path_out, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(path_cuencas)) {
  stop("No existe el archivo de cuencas: ", path_cuencas, call. = FALSE)
}

sector_lookup <- tibble::tribble(
  ~RID, ~sector, ~sector_slug,
  1808, "Punta Arenas / Laredo", "punta_arenas_laredo",
  1885, "Norponiente", "norponiente",
  2205, "Norponiente", "norponiente",
  1886, "Norponiente", "norponiente",
  5257, "Norponiente", "norponiente",
  3289, "Norponiente", "norponiente",
  4982, "Eje norte intermedio", "eje_norte_intermedio",
  4996, "Eje norte intermedio", "eje_norte_intermedio",
  5209, "Eje norte intermedio", "eje_norte_intermedio",
  5258, "Eje norte intermedio", "eje_norte_intermedio",
  5247, "Eje norte intermedio", "eje_norte_intermedio",
  5294, "Eje oriental", "eje_oriental",
  5624, "Eje oriental", "eje_oriental",
  5048, "Eje oriental", "eje_oriental",
  5263, "Eje oriental", "eje_oriental",
  5626, "Eje oriental", "eje_oriental",
  5623, "Eje oriental", "eje_oriental"
)

make_popup <- function(x, cols) {
  attrs <- x |>
    st_drop_geometry() |>
    select(any_of(cols))

  lapply(seq_len(nrow(attrs)), function(i) {
    values <- attrs[i, , drop = FALSE]

    rows <- vapply(names(values), function(nm) {
      value <- values[[nm]][1]
      if (is.numeric(value)) value <- signif(value, 4)
      if (is.na(value)) value <- ""

      paste0(
        "<tr>",
        "<th style='text-align:left;padding-right:8px;'>",
        htmltools::htmlEscape(nm),
        "</th>",
        "<td>",
        htmltools::htmlEscape(as.character(value)),
        "</td>",
        "</tr>"
      )
    }, character(1))

    paste0("<table>", paste(rows, collapse = ""), "</table>")
  })
}

read_sector_layer <- function(path) {
  st_read(path, quiet = TRUE) |>
    st_make_valid() |>
    left_join(sector_lookup, by = "RID")
}

# Leer insumos ------------------------------------------------------------

cuencas <- read_sector_layer(path_cuencas) |>
  st_transform(4326)

missing_cuencas <- cuencas |>
  filter(is.na(sector)) |>
  st_drop_geometry() |>
  pull(RID)

if (length(missing_cuencas) > 0) {
  stop(
    "Hay cuencas sin sector operativo asignado: ",
    paste(missing_cuencas, collapse = ", "),
    call. = FALSE
  )
}

if (!"RES_ST" %in% names(cuencas)) {
  stop("La capa de cuencas no contiene el campo RES_ST.", call. = FALSE)
}

popup_cols_cuencas <- c(
  "RID", "sector", "DIV", "PT", "Estado_Din", "RES_ST",
  "VEL_CLASS", "ACC_CLASS", "Tipo", "DYN_REG", "JERK_CLASS",
  "RES_TYP", "RES", "DOMAIN", "DOM_LOC", "VEL", "ACC", "JERK",
  "SENS"
)

accesos <- NULL
if (file.exists(path_accesos)) {
  accesos <- read_sector_layer(path_accesos) |>
    st_transform(4326)

  missing_accesos <- accesos |>
    filter(is.na(sector)) |>
    st_drop_geometry() |>
    pull(RID)

  if (length(missing_accesos) > 0) {
    stop(
      "Hay puntos de acceso sin sector operativo asignado: ",
      paste(missing_accesos, collapse = ", "),
      call. = FALSE
    )
  }
}

popup_cols_accesos <- c(
  "RID", "sector", "Comuna", "Terminal", "Ranking", "RES_ST",
  "Tipo", "Año_crít", "Distancia_", "P_score", "POINT_X", "POINT_Y"
)

# Generar mapas ----------------------------------------------------------

mapviewOptions(
  basemaps = c(
    "Esri.WorldImagery",
    "Esri.WorldStreetMap",
    "Esri.WorldTopoMap",
    "CartoDB.Positron",
    "OpenStreetMap"
  )
)

sectors <- sector_lookup |>
  distinct(sector, sector_slug)

for (i in seq_len(nrow(sectors))) {
  sector_name <- sectors$sector[i]
  sector_slug <- sectors$sector_slug[i]

  cuencas_sector <- cuencas |>
    filter(sector_slug == !!sector_slug) |>
    select(any_of(popup_cols_cuencas))

  accesos_sector <- NULL
  if (!is.null(accesos)) {
    accesos_sector <- accesos |>
      filter(sector_slug == !!sector_slug) |>
      select(any_of(popup_cols_accesos))
  }

  mapa <- mapview(
    cuencas_sector,
    zcol = "RES_ST",
    layer.name = paste0("Cuencas - ", sector_name),
    alpha.regions = 0.55,
    lwd = 2,
    legend = TRUE,
    label = paste0(
      "RID ", cuencas_sector$RID,
      " · ", cuencas_sector$RES_ST
    ),
    popup = make_popup(cuencas_sector, popup_cols_cuencas)
  )

  if (!is.null(accesos_sector) && nrow(accesos_sector) > 0) {
    mapa <- mapa + mapview(
      accesos_sector,
      layer.name = paste0("Puntos de acceso - ", sector_name),
      col.regions = "#1f78b4",
      cex = 5,
      legend = FALSE,
      popup = make_popup(accesos_sector, popup_cols_accesos)
    )
  }

  file_out <- file.path(path_out, paste0("mapa_sector_", sector_slug, ".html"))

  saveWidget(
    widget = mapa@map,
    file = file_out,
    selfcontained = TRUE,
    title = paste0("Mapa sector ", sector_name)
  )

  message("Mapa sectorial guardado en: ", normalizePath(file_out))
}
