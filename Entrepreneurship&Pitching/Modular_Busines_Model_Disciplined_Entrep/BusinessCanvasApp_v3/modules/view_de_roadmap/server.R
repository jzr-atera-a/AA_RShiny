view_de_roadmap_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Load default roadmap display with 24 steps
    load_default_roadmap <- function() {
      output$roadmap_display <- renderUI({
        HTML('
          <div class="de-roadmap-container" style="padding: 20px;">
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">1</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Market Segmentation</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">2</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Select a Beachhead Market</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">3</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Build an End User Profile</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">4</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Calculate TAM Size for Beachhead Market</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">5</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Profile the Persona</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="position: relative; border: 3px solid #2563EB; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">6</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Full Life Cycle Use Case</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="position: relative; border: 3px solid #2563EB; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">7</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">High-Level Product Specification</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="position: relative; border: 3px solid #2563EB; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">8</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Quantify the Value Proposition</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">9</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Identify Your Next 10 Customers</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="position: relative; border: 3px solid #2563EB; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">10</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Define Your Core</div>
              </div>
              <div class="de-roadmap-box roadmap-cat2" style="position: relative; border: 3px solid #2563EB; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #3B82F6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">11</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Chart Your Competitive Position</div>
              </div>
              <div class="de-roadmap-box roadmap-cat1" style="position: relative; border: 3px solid #0284C7; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #0EA5E9; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">12</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Determine the DMU</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat3" style="position: relative; border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">13</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Map Process to Acquire Customer</div>
              </div>
              <div class="de-roadmap-box roadmap-cat3" style="position: relative; border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">14</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Calculate TAM for Follow-on Markets</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="position: relative; border: 3px solid #0891B2; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">15</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Design a Business Model</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="position: relative; border: 3px solid #0891B2; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">16</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Set Your Pricing Framework</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat4" style="position: relative; border: 3px solid #0891B2; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">17</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Calculate LTV</div>
              </div>
              <div class="de-roadmap-box roadmap-cat3" style="position: relative; border: 3px solid #1E3A8A; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #1E40AF; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">18</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Map Sales Process</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="position: relative; border: 3px solid #0891B2; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">19</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Calculate CAC</div>
              </div>
              <div class="de-roadmap-box roadmap-cat4" style="position: relative; border: 3px solid #0891B2; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #06B6D4; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">20</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Identify Key Assumptions</div>
              </div>
            </div>
            
            <div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">
              <div class="de-roadmap-box roadmap-cat5" style="position: relative; border: 3px solid #0D9488; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">21</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Test Key Assumptions</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="position: relative; border: 3px solid #0D9488; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">22</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Define the MVBP</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="position: relative; border: 3px solid #0D9488; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">23</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Dogs Eat Dog Food</div>
              </div>
              <div class="de-roadmap-box roadmap-cat5" style="position: relative; border: 3px solid #0D9488; border-radius: 15px; padding: 15px 12px; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); text-align: center;">
                <div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: #14B8A6; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">24</div>
                <div style="font-weight: bold; font-size: 13px; margin-top: 10px; line-height: 1.3;">Develop Product Plan</div>
              </div>
            </div>
          </div>
        ')
      })
    }
    
    # Render loaded roadmap in same grid format
    render_roadmap_grid <- function(result) {
      # Define box styles for each step (matching default colors and categories)
      box_styles <- c(
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;', # Steps 1-4
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;',
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;',
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;',
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;', # Step 5
        'border: 3px solid #2563EB; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: #3B82F6;', # Steps 6-8
        'border: 3px solid #2563EB; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: #3B82F6;',
        'border: 3px solid #2563EB; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: #3B82F6;',
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;', # Step 9
        'border: 3px solid #2563EB; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: #3B82F6;', # Steps 10-11
        'border: 3px solid #2563EB; background: linear-gradient(135deg, #3B82F6, #60A5FA); color: #3B82F6;',
        'border: 3px solid #0284C7; background: linear-gradient(135deg, #0EA5E9, #38BDF8); color: #0EA5E9;', # Step 12
        'border: 3px solid #1E3A8A; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: #1E40AF;', # Steps 13-14
        'border: 3px solid #1E3A8A; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: #1E40AF;',
        'border: 3px solid #0891B2; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: #06B6D4;', # Steps 15-17, 19-20
        'border: 3px solid #0891B2; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: #06B6D4;',
        'border: 3px solid #0891B2; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: #06B6D4;',
        'border: 3px solid #1E3A8A; background: linear-gradient(135deg, #1E40AF, #3B82F6); color: #1E40AF;', # Step 18
        'border: 3px solid #0891B2; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: #06B6D4;',
        'border: 3px solid #0891B2; background: linear-gradient(135deg, #06B6D4, #22D3EE); color: #06B6D4;',
        'border: 3px solid #0D9488; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: #14B8A6;', # Steps 21-24
        'border: 3px solid #0D9488; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: #14B8A6;',
        'border: 3px solid #0D9488; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: #14B8A6;',
        'border: 3px solid #0D9488; background: linear-gradient(135deg, #14B8A6, #2DD4BF); color: #14B8A6;'
      )
      
      step_titles <- c(
        'Market Segmentation', 'Select a Beachhead Market', 'Build an End User Profile', 'Calculate TAM Size for Beachhead Market',
        'Profile the Persona', 'Full Life Cycle Use Case', 'High-Level Product Specification', 'Quantify the Value Proposition',
        'Identify Your Next 10 Customers', 'Define Your Core', 'Chart Your Competitive Position', 'Determine the DMU',
        'Map Process to Acquire Customer', 'Calculate TAM for Follow-on Markets', 'Design a Business Model', 'Set Your Pricing Framework',
        'Calculate LTV', 'Map Sales Process', 'Calculate CAC', 'Identify Key Assumptions',
        'Test Key Assumptions', 'Define the MVBP', 'Dogs Eat Dog Food', 'Develop Product Plan'
      )
      
      step_cols <- c("step_01_market_segmentation", "step_02_select_beachhead_market", "step_03_build_end_user_profile",
                     "step_04_calculate_tam_beachhead", "step_05_profile_persona", "step_06_full_life_cycle_use_case",
                     "step_07_high_level_product_spec", "step_08_quantify_value_proposition", "step_09_identify_next_10_customers",
                     "step_10_define_your_core", "step_11_chart_competitive_position", "step_12_determine_dmu",
                     "step_13_map_process_acquire_customer", "step_14_calculate_tam_followon", "step_15_design_business_model",
                     "step_16_set_pricing_framework", "step_17_calculate_ltv", "step_18_map_sales_process",
                     "step_19_calculate_cac", "step_20_identify_key_assumptions", "step_21_test_key_assumptions",
                     "step_22_define_mvbp", "step_23_dogs_eat_dog_food", "step_24_develop_product_plan")
      
      html_output <- '<div class="de-roadmap-container" style="padding: 20px;">'
      
      # Build 6 rows of 4 steps each
      for (row in 1:6) {
        html_output <- paste0(html_output, '<div class="de-roadmap-grid" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 12px;">')
        
        for (col in 1:4) {
          step_num <- (row - 1) * 4 + col
          step_content <- if (step_cols[step_num] %in% names(result)) result[[step_cols[step_num]]] else ""
          
          # Extract color for number circle from box_styles
          num_color <- sub(".*color: ([^;]+);.*", "\\1", box_styles[step_num])
          
          html_output <- paste0(html_output,
                                '<div class="de-roadmap-box" style="position: relative; ', box_styles[step_num], 
                                ' border-radius: 15px; padding: 50px 12px 15px 12px; color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); min-height: 150px; overflow-y: auto;">',
                                '<div style="position: absolute; top: 10px; left: 10px; width: 35px; height: 35px; border-radius: 50%; background: ', num_color, '; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);">', step_num, '</div>',
                                '<div style="font-weight: bold; font-size: 12px; line-height: 1.3; margin-bottom: 8px; text-align: center;">', step_titles[step_num], '</div>',
                                '<div style="font-size: 11px; line-height: 1.4; text-align: left;">', gsub("\n", "<br>", step_content), '</div>',
                                '</div>')
        }
        
        html_output <- paste0(html_output, '</div>')
      }
      
      html_output <- paste0(html_output, '</div>')
      return(HTML(html_output))
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
      if (!api_manager$bq_authenticated || input$roadmap_select_business_area == "" || 
          input$roadmap_select_project == "" || input$roadmap_select_business_focus == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         roadmap_table, 
                         gsub("'", "\\\\'", input$roadmap_select_business_area), 
                         gsub("'", "\\\\'", input$roadmap_select_project), 
                         gsub("'", "\\\\'", input$roadmap_select_business_focus))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          # Render in beautiful grid format (same as default)
          output$roadmap_display <- renderUI({
            render_roadmap_grid(result)
          })
          showNotification("✓ Roadmap loaded!", type = "message")
        } else {
          showNotification("No roadmap found", type = "warning")
          load_default_roadmap()
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
        load_default_roadmap()
      })
    })
    
    load_default_roadmap()
  })
}