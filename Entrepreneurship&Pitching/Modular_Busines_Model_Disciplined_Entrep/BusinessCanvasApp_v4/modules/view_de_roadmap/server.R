view_de_roadmap_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Load default roadmap display with 24 steps
    load_default_roadmap <- function() {
      output$roadmap_display <- renderUI({
        HTML('
          <div class="de-roadmap-container" style="padding: 20px;">
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">1</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Market Segmentation</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">2</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Select a Beachhead Market</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">3</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Build an End User Profile</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">4</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Calculate TAM Size for Beachhead Market</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">5</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Profile the Persona</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="border: 3px solid #2563EB; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">6</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Full Life Cycle Use Case</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="border: 3px solid #2563EB; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">7</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">High-Level Product Specification</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="border: 3px solid #2563EB; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">8</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Quantify the Value Proposition</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">9</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Identify Your Next 10 Customers</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="border: 3px solid #2563EB; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">10</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Define Your Core</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="border: 3px solid #2563EB; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">11</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Chart Your Competitive Position</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="border: 3px solid #0284C7; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">12</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Determine the DMU</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat3" style="border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">13</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Map Process to Acquire Customer</div>
              </div>
              <div class="de-roadmap-box roadmap-cat3" style="border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">14</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Calculate TAM for Follow-on Markets</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="border: 3px solid #0891B2; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">15</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Design a Business Model</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="border: 3px solid #0891B2; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">16</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Set Your Pricing Framework</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat4" style="border: 3px solid #0891B2; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">17</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Calculate LTV</div>
              </div>
              <div class="de-roadmap-box roadmap-cat3" style="border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">18</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Map Sales Process</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="border: 3px solid #0891B2; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">19</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Calculate CAC</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="border: 3px solid #0891B2; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">20</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Identify Key Assumptions</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat5" style="border: 3px solid #0D9488; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">21</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Test Key Assumptions</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="border: 3px solid #0D9488; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">22</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Define the MVBP</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="border: 3px solid #0D9488; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">23</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Dogs Eat Dog Food</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="border: 3px solid #0D9488; border-radius: 15px; padding: 15px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div class="de-roadmap-number" style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px;">24</div>
                <div class="de-roadmap-title" style="font-weight: bold; font-size: 13px; margin-top: 10px;">Develop Product Plan</div>
              </div>
            </div>
          </div>
        ')
      })
    }
    
    update_roadmap_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      cat("🔍 DE Roadmap - Updating dropdowns...\n")
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", roadmap_table)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        cat("✓ DE Roadmap - Found", nrow(result), "business areas\n")
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_business_area", choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {
        cat("✗ DE Roadmap - Error:", e$message, "\n")
      })
    }
    
    observe({
      api_manager$bq_auth_trigger()
      if (api_manager$bq_authenticated) {
        cat("🔔 DE Roadmap - Auth trigger fired!\n")
        update_roadmap_dropdowns()
      }
    })
    
    observeEvent(input$roadmap_select_business_area, {
      if (input$roadmap_select_business_area == "" || !api_manager$bq_authenticated) return()
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         roadmap_table, gsub("'", "\\\\'", input$roadmap_select_business_area))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_project", choices = c("Select..." = "", result$project))
        }
      }, error = function(e) { })
    })
    
    observeEvent(input$roadmap_select_project, {
      if (input$roadmap_select_project == "" || !api_manager$bq_authenticated) return()
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         roadmap_table, gsub("'", "\\\\'", input$roadmap_select_business_area), gsub("'", "\\\\'", input$roadmap_select_project))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_business_focus", choices = c("Select..." = "", result$business_focus))
        }
      }, error = function(e) { })
    })
    
    observeEvent(input$loadRoadmap, {
      if (!api_manager$bq_authenticated || input$roadmap_select_business_area == "" || input$roadmap_select_project == "" || input$roadmap_select_business_focus == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         roadmap_table, gsub("'", "\\\\'", input$roadmap_select_business_area), gsub("'", "\\\\'", input$roadmap_select_project), gsub("'", "\\\\'", input$roadmap_select_business_focus))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          steps_html <- '<div style="padding: 20px;">'
          step_cols <- c("step_01_market_segmentation", "step_02_select_beachhead_market", "step_03_build_end_user_profile",
                         "step_04_calculate_tam_beachhead", "step_05_profile_persona", "step_06_full_life_cycle_use_case",
                         "step_07_high_level_product_spec", "step_08_quantify_value_proposition", "step_09_identify_next_10_customers",
                         "step_10_define_your_core", "step_11_chart_competitive_position", "step_12_determine_dmu",
                         "step_13_map_process_acquire_customer", "step_14_calculate_tam_followon", "step_15_design_business_model",
                         "step_16_set_pricing_framework", "step_17_calculate_ltv", "step_18_map_sales_process",
                         "step_19_calculate_cac", "step_20_identify_key_assumptions", "step_21_test_key_assumptions",
                         "step_22_define_mvbp", "step_23_dogs_eat_dog_food", "step_24_develop_product_plan")
          for (i in 1:24) {
            if (step_cols[i] %in% names(result)) {
              steps_html <- paste0(steps_html, '<div style="margin-bottom: 20px; padding: 15px; background: white; border-radius: 8px; border-left: 4px solid #008A82;">',
                                   '<h4 style="color: #008A82; margin-top: 0;">Step ', i, '</h4>',
                                   '<div style="line-height: 1.6;">', gsub("\n", "<br>", result[[step_cols[i]]]), '</div></div>')
            }
          }
          steps_html <- paste0(steps_html, '</div>')
          output$roadmap_display <- renderUI({ HTML(steps_html) })
          showNotification("✓ Roadmap loaded!", type = "message")
        }
      }, error = function(e) { })
    })
    
    # Initialize with default roadmap display
    load_default_roadmap()
  })
}
