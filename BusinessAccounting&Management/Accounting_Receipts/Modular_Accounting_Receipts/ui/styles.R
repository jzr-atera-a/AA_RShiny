# UI Styles
includeCSS_styles <- function() {
  tags$head(
    tags$style(HTML("
      /* Paleta de colores */
      :root {
        --deep-blue: #0a1128;
        --dark-blue: #1e3c72;
        --medium-blue: #2a5298;
        --bright-blue: #4a90e2;
        --light-blue: #7ec8e3;
        --purple-dark: #3d1f4f;
        --purple-medium: #5e2e6c;
        --purple-light: #764ba2;
      }
      
      .skin-blue .main-header .navbar {
        background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
        border-bottom: 3px solid #7ec8e3;
      }
      
      .skin-blue .main-header .logo {
        background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
        color: #ffffff !important;
        font-weight: 600;
        border-right: 2px solid #4a90e2;
      }
      
      .skin-blue .main-sidebar {
        background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
        box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
      }
      
      .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        color: #ffffff !important;
        font-weight: bold;
        border-left: 4px solid #7ec8e3;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
      }
      
      .skin-blue .main-sidebar .sidebar .sidebar-menu a {
        color: #e0e7ff !important;
        transition: all 0.3s ease;
      }
      
      .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        color: #ffffff !important;
        border-left: 4px solid #7ec8e3;
        transform: translateX(5px);
      }
      
      .content-wrapper {
        background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
      }
      
      .box {
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
        border: 2px solid #4a90e2 !important;
        border-radius: 12px !important;
        box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
        transition: all 0.3s ease;
      }
      
      .box:hover {
        box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
        transform: translateY(-2px);
      }
      
      .box.box-primary .box-header {
        color: #ffffff !important;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        border-radius: 10px 10px 0 0 !important;
        border-bottom: 2px solid #4a90e2 !important;
        padding: 15px;
        font-weight: 600;
      }
      
      .box.box-info .box-header {
        color: #ffffff !important;
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        border-radius: 10px 10px 0 0 !important;
        border-bottom: 2px solid #7ec8e3 !important;
        padding: 15px;
        font-weight: 600;
      }
      
      .box.box-success .box-header {
        color: #ffffff !important;
        background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
        border-radius: 10px 10px 0 0 !important;
        border-bottom: 2px solid #7ec8e3 !important;
        padding: 15px;
        font-weight: 600;
      }
      
      .box.box-warning .box-header {
        color: #ffffff !important;
        background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        border-radius: 10px 10px 0 0 !important;
        border-bottom: 2px solid #7ec8e3 !important;
        padding: 15px;
        font-weight: 600;
      }
      
      .box-body {
        background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
        color: #e0e7ff !important;
        padding: 20px !important;
        border-radius: 0 0 10px 10px;
      }
      
      p { 
        color: #c7d2fe !important; 
        line-height: 1.7 !important; 
      }
      
      strong { 
        color: #7ec8e3 !important; 
        font-weight: 600;
      }
      
      h3, h4, h5, h6 {
        color: #ffffff !important;
      }
      
      .form-control {
        background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
        color: #ffffff !important;
        border: 2px solid #4a90e2 !important;
        border-radius: 8px;
      }
      
      .btn {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        color: #ffffff !important;
        border: none !important;
        border-radius: 8px;
        padding: 10px 20px;
        font-weight: bold;
        transition: all 0.3s ease;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
      }
      
      .btn:hover {
        background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
      }
      
      .btn-success {
        background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
      }
      
      .btn-info {
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
      }
      
      .btn-warning {
        background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
      }
      
      .btn-primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
      }
      
      .info-box {
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
        color: #ffffff !important;
        border: 2px solid #4a90e2;
        border-radius: 8px;
        box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3);
      }
      
      .info-box-icon {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
      }
      
      .info-box-text {
        color: #e0e7ff !important;
      }
      
      .info-box-number {
        color: #7ec8e3 !important;
        font-weight: bold;
      }
      
      table.dataTable {
        background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
        color: #e0e7ff !important;
      }
      
      table.dataTable thead th {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        color: #ffffff !important;
        border-bottom: 2px solid #4a90e2 !important;
      }
      
      table.dataTable tbody tr {
        background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
        color: #e0e7ff !important;
      }
      
      table.dataTable tbody tr:hover {
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
      }
      
      ::-webkit-scrollbar {
        width: 12px;
      }
      
      ::-webkit-scrollbar-track {
        background: #0a1128;
      }
      
      ::-webkit-scrollbar-thumb {
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%);
        border-radius: 6px;
      }
      
      .alert-success {
        background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
        border-color: #7ec8e3 !important;
        color: #ffffff !important;
        padding: 15px;
        border-radius: 8px;
        margin: 10px 0;
      }
      
      .alert-danger {
        background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        border-color: #e74c3c !important;
        color: #ffffff !important;
        padding: 15px;
        border-radius: 8px;
        margin: 10px 0;
      }
      
      .alert-info {
        background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        border-color: #7ec8e3 !important;
        color: #ffffff !important;
        padding: 15px;
        border-radius: 8px;
        margin: 10px 0;
      }
      
      .category-totals {
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
        border: 2px solid #4a90e2;
        border-radius: 8px;
        padding: 20px;
        margin: 20px 0;
      }
      
      .category-total-item {
        display: inline-block;
        margin: 10px 15px;
        padding: 15px 25px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        border-radius: 8px;
        min-width: 150px;
        text-align: center;
      }
      
      .category-total-label {
        color: #e0e7ff;
        font-size: 14px;
        font-weight: 600;
      }
      
      .category-total-amount {
        color: #7ec8e3;
        font-size: 24px;
        font-weight: bold;
        margin-top: 5px;
      }
    "))
  )
}
