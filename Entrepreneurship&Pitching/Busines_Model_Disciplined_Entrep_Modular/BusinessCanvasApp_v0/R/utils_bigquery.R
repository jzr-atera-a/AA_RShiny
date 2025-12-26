# R/utils_bigquery.R
# BigQuery table schemas and utilities

# Table schema definitions
BQ_SCHEMAS <- list(
  
  # Business Model Canvas table schema
  business_model_canvas = "
    CREATE TABLE IF NOT EXISTS `%s` (
      canvas_id STRING NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      business_area STRING,
      project STRING,
      business_focus STRING,
      key_partners STRING,
      key_activities STRING,
      key_resources STRING,
      value_propositions STRING,
      customer_relationships STRING,
      channels STRING,
      customer_segments STRING,
      cost_structure STRING,
      revenue_streams STRING
    )",
  
  # Disciplined Entrepreneurship Canvas table schema
  disciplined_entrepreneurship_canvas = "
    CREATE TABLE IF NOT EXISTS `%s` (
      canvas_id STRING NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      business_area STRING,
      project STRING,
      business_focus STRING,
      raison_detre STRING,
      initial_market STRING,
      value_creation STRING,
      competitive_advantage STRING,
      customer_acquisition STRING,
      product_unit_economics STRING,
      sales STRING,
      overall_economics STRING,
      design_build STRING,
      scaling STRING
    )",
  
  # Disciplined Entrepreneurship Roadmap table schema
  disciplined_entrepreneurship_roadmap = "
    CREATE TABLE IF NOT EXISTS `%s` (
      roadmap_id STRING NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
      business_area STRING,
      project STRING,
      business_focus STRING,
      step_01_market_segmentation STRING,
      step_02_select_beachhead_market STRING,
      step_03_build_end_user_profile STRING,
      step_04_calculate_tam_beachhead STRING,
      step_05_profile_persona STRING,
      step_06_full_life_cycle_use_case STRING,
      step_07_high_level_product_spec STRING,
      step_08_quantify_value_proposition STRING,
      step_09_identify_next_10_customers STRING,
      step_10_define_your_core STRING,
      step_11_chart_competitive_position STRING,
      step_12_determine_dmu STRING,
      step_13_map_process_acquire_customer STRING,
      step_14_calculate_tam_followon STRING,
      step_15_design_business_model STRING,
      step_16_set_pricing_framework STRING,
      step_17_calculate_ltv STRING,
      step_18_map_sales_process STRING,
      step_19_calculate_cac STRING,
      step_20_identify_key_assumptions STRING,
      step_21_test_key_assumptions STRING,
      step_22_define_mvbp STRING,
      step_23_dogs_eat_dog_food STRING,
      step_24_develop_product_plan STRING
    )"
)

# Create table if not exists
create_bq_table <- function(api_manager, table_type, custom_table_id = NULL) {
  if (!api_manager$bq_authenticated) {
    stop("BigQuery not authenticated")
  }
  
  schema <- BQ_SCHEMAS[[table_type]]
  if (is.null(schema)) {
    stop("Unknown table type: ", table_type)
  }
  
  # Determine table ID
  if (!is.null(custom_table_id)) {
    full_table_id <- paste0(api_manager$bq_project_id, ".", 
                            api_manager$bq_dataset_id, ".", 
                            custom_table_id)
  } else {
    full_table_id <- api_manager$bq_full_table_id
  }
  
  # Create table
  create_query <- sprintf(schema, full_table_id)
  
  tryCatch({
    bigrquery::bq_project_query(api_manager$bq_project_id, create_query)
    return(TRUE)
  }, error = function(e) {
    warning("Error creating table: ", e$message)
    return(FALSE)
  })
}

# Get distinct values from column
get_distinct_values <- function(api_manager, column_name, table_name = NULL) {
  if (!api_manager$bq_authenticated) {
    return(character(0))
  }
  
  table_id <- if (!is.null(table_name)) {
    paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".", table_name)
  } else {
    api_manager$bq_full_table_id
  }
  
  query <- sprintf("SELECT DISTINCT %s FROM `%s` WHERE %s IS NOT NULL ORDER BY %s", 
                   column_name, table_id, column_name, column_name)
  
  tryCatch({
    result <- api_manager$query_bigquery(query)
    if (nrow(result) > 0) {
      return(result[[column_name]])
    } else {
      return(character(0))
    }
  }, error = function(e) {
    return(character(0))
  })
}

# Get filtered distinct values (cascading dropdowns)
get_filtered_values <- function(api_manager, column_name, filters, table_name = NULL) {
  if (!api_manager$bq_authenticated) {
    return(character(0))
  }
  
  table_id <- if (!is.null(table_name)) {
    paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".", table_name)
  } else {
    api_manager$bq_full_table_id
  }
  
  # Build WHERE clause
  where_clauses <- c()
  for (filter_col in names(filters)) {
    if (!is.null(filters[[filter_col]]) && filters[[filter_col]] != "") {
      filter_value_clean <- clean_for_sql(filters[[filter_col]])
      where_clauses <- c(where_clauses, 
                        sprintf("%s = '%s'", filter_col, filter_value_clean))
    }
  }
  
  where_clause <- if (length(where_clauses) > 0) {
    paste("WHERE", paste(where_clauses, collapse = " AND "))
  } else {
    "WHERE 1=1"
  }
  
  query <- sprintf("SELECT DISTINCT %s FROM `%s` %s AND %s IS NOT NULL ORDER BY %s", 
                   column_name, table_id, where_clause, column_name, column_name)
  
  tryCatch({
    result <- api_manager$query_bigquery(query)
    if (nrow(result) > 0) {
      return(result[[column_name]])
    } else {
      return(character(0))
    }
  }, error = function(e) {
    return(character(0))
  })
}

# Load record from BigQuery
load_record <- function(api_manager, business_area, project, business_focus, table_name = NULL) {
  if (!api_manager$bq_authenticated) {
    return(NULL)
  }
  
  table_id <- if (!is.null(table_name)) {
    paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".", table_name)
  } else {
    api_manager$bq_full_table_id
  }
  
  business_area_clean <- clean_for_sql(business_area)
  project_clean <- clean_for_sql(project)
  business_focus_clean <- clean_for_sql(business_focus)
  
  query <- sprintf("
    SELECT * FROM `%s` 
    WHERE business_area = '%s' 
    AND project = '%s' 
    AND business_focus = '%s' 
    ORDER BY updated_at DESC 
    LIMIT 1",
    table_id,
    business_area_clean,
    project_clean,
    business_focus_clean
  )
  
  tryCatch({
    result <- api_manager$query_bigquery(query)
    if (nrow(result) > 0) {
      return(result)
    } else {
      return(NULL)
    }
  }, error = function(e) {
    warning("Error loading record: ", e$message)
    return(NULL)
  })
}

cat("✔ BigQuery utilities loaded\n")
