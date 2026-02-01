let
  default = import ./default.nix;
  defaultPkgs = default.pkgs;
  defaultShell = default.shell;
  defaultBuildInputs = defaultShell.buildInputs;
  defaultConfigurePhase = ''
    cp ${./_rixpress/default_libraries.R} libraries.R
    mkdir -p $out  
    mkdir -p .julia_depot  
    export JULIA_DEPOT_PATH=$PWD/.julia_depot  
    export HOME_PATH=$PWD
  '';
  
  # Function to create R derivations
  makeRDerivation = { name, buildInputs, configurePhase, buildPhase, src ? null }:
    defaultPkgs.stdenv.mkDerivation {
      inherit name src;
      dontUnpack = true;
      inherit buildInputs configurePhase buildPhase;
      installPhase = ''
        cp ${name} $out/
      '';
    };

  # Define all derivations
    anime_raw = makeRDerivation {
    name = "anime_raw";
    src = defaultPkgs.lib.fileset.toSource {
      root = ./.;
      fileset = defaultPkgs.lib.fileset.unions [ ./data/anime.csv ];
    };
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      cp -r $src input_folder
Rscript -e "
source('libraries.R')
data <- do.call(function(x) readr::read_csv(x, show_col_types = FALSE), list('input_folder/data/anime.csv'))
saveRDS(data, 'anime_raw')"
    '';
  };

  manga_raw = makeRDerivation {
    name = "manga_raw";
    src = defaultPkgs.lib.fileset.toSource {
      root = ./.;
      fileset = defaultPkgs.lib.fileset.unions [ ./data/manga.csv ];
    };
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      cp -r $src input_folder
Rscript -e "
source('libraries.R')
data <- do.call(function(x) readr::read_csv(x, show_col_types = FALSE), list('input_folder/data/manga.csv'))
saveRDS(data, 'manga_raw')"
    '';
  };

  anime_clean = makeRDerivation {
    name = "anime_clean";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        anime_raw <- readRDS('${anime_raw}/anime_raw')
        anime_clean <- {     filter(transmute(janitor::clean_names(anime_raw), medium = 'anime', id = anime_id, title = title, type = type, score = as.numeric(score), scored_by = as.numeric(scored_by), members = as.numeric(members), favorites = as.numeric(favorites), sfw = as.logical(sfw), approved = as.logical(approved), start_date = suppressWarnings(lubridate::ymd(start_date)), start_year = as.integer(start_year), status = status, genres = genres, themes = themes, demographics = demographics), !is.na(score), score >= 0,          score <= 10, !is.na(members), members > 0) }
        saveRDS(anime_clean, 'anime_clean')"
    '';
  };

  manga_clean = makeRDerivation {
    name = "manga_clean";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        manga_raw <- readRDS('${manga_raw}/manga_raw')
        manga_clean <- {     filter(transmute(janitor::clean_names(manga_raw), medium = 'manga', id = manga_id, title = title, type = type, score = as.numeric(score), scored_by = as.numeric(scored_by), members = as.numeric(members), favorites = as.numeric(favorites), sfw = as.logical(sfw), approved = as.logical(approved), start_date = suppressWarnings(lubridate::ymd(start_date)), start_year = as.integer(lubridate::year(start_date)), status = status, genres = genres, themes = themes, demographics = demographics), !is.na(score),          score >= 0, score <= 10, !is.na(members), members > 0) }
        saveRDS(manga_clean, 'manga_clean')"
    '';
  };

  combined = makeRDerivation {
    name = "combined";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        anime_clean <- readRDS('${anime_clean}/anime_clean')
        manga_clean <- readRDS('${manga_clean}/manga_clean')
        combined <- bind_rows(anime_clean, manga_clean)
        saveRDS(combined, 'combined')"
    '';
  };

  summary_by_medium = makeRDerivation {
    name = "summary_by_medium";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        combined <- readRDS('${combined}/combined')
        summary_by_medium <- {     summarise(group_by(combined, medium), n = n(), score_mean = mean(score, na.rm = TRUE), score_median = median(score, na.rm = TRUE), members_median = median(members, na.rm = TRUE), favorites_median = median(favorites, na.rm = TRUE), .groups = 'drop') }
        saveRDS(summary_by_medium, 'summary_by_medium')"
    '';
  };

  corr_score_popularity = makeRDerivation {
    name = "corr_score_popularity";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        combined <- readRDS('${combined}/combined')
        corr_score_popularity <- {     summarise(group_by(mutate(combined, members_log10 = log10(members)), medium), n = n(), pearson = cor(members_log10, score, use = 'complete.obs', method = 'pearson'), spearman = cor(members_log10, score, use = 'complete.obs', method = 'spearman'), .groups = 'drop') }
        saveRDS(corr_score_popularity, 'corr_score_popularity')"
    '';
  };

  plot_score_vs_popularity = makeRDerivation {
    name = "plot_score_vs_popularity";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        combined <- readRDS('${combined}/combined')
        plot_score_vs_popularity <- {     ggplot(mutate(combined, members_log10 = log10(members)), aes(x = members_log10, y = score, color = medium)) + geom_point(alpha = 0.25, size = 0.8) + geom_smooth(se = FALSE, method = 'loess', formula = y ~ x) + labs(title = 'Score vs popularity (log10 members)', x = 'log10(members)', y = 'score') + theme_minimal() }
        saveRDS(plot_score_vs_popularity, 'plot_score_vs_popularity')"
    '';
  };

  # Generic default target that builds all derivations
  allDerivations = defaultPkgs.symlinkJoin {
    name = "all-derivations";
    paths = with builtins; attrValues { inherit anime_raw manga_raw anime_clean manga_clean combined summary_by_medium corr_score_popularity plot_score_vs_popularity; };
  };

in
{
  inherit anime_raw manga_raw anime_clean manga_clean combined summary_by_medium corr_score_popularity plot_score_vs_popularity;
  default = allDerivations;
}
