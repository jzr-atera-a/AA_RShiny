# Data Viewer Module

## Description
View and filter data with cascading dropdown controls.

## Features
- Cascading dropdowns (Level 1 → Level 2)
- Interactive data table with sorting and search
- Summary statistics
- Status breakdown

## Dependencies
- shiny
- shinydashboard
- DT

## Inputs
- `category`: Primary filter (Level 1)
- `subcategory`: Secondary filter (Level 2, depends on category)
- `load`: Button to load filtered data

## Outputs
- `data_table`: Interactive table with data
- `data_summary`: Statistical summary
- `filter_status`: Status messages

## Customization
- Replace sample data generation with real database queries
- Add more filter levels
- Customize summary statistics
- Connect to api_manager for authenticated data access
