# Generate Sample Excel Template with Email Examples
# This script creates a sample Gantt chart template with proper email formatting

library(writexl)

# Create sample data with various email formats
sample_data <- data.frame(
  Task_Name = c(
    "Project Kickoff Meeting",
    "Requirements Gathering",
    "System Architecture Design",
    "Frontend Development",
    "Backend API Development",
    "Database Setup",
    "UI/UX Design",
    "Integration Testing",
    "Security Audit",
    "Deployment Setup",
    "User Documentation",
    "Training Sessions"
  ),
  Description = c(
    "Initial project meeting with all stakeholders to align on goals and timeline",
    "Collect and document all functional and non-functional requirements",
    "Design overall system architecture including tech stack decisions",
    "Develop user-facing components using React and TypeScript",
    "Create REST APIs for all business logic and data operations",
    "Setup PostgreSQL database with initial schema and migrations",
    "Create wireframes and high-fidelity mockups for all screens",
    "Test integration between frontend, backend, and database",
    "Perform security review and penetration testing",
    "Configure CI/CD pipeline and production environment",
    "Write comprehensive user guides and API documentation",
    "Conduct training sessions for end users and administrators"
  ),
  Start_Date = c(
    "2025-01-15",
    "2025-01-16",
    "2025-01-20",
    "2025-01-27",
    "2025-01-27",
    "2025-01-23",
    "2025-01-22",
    "2025-02-10",
    "2025-02-17",
    "2025-02-20",
    "2025-02-15",
    "2025-02-24"
  ),
  End_Date = c(
    "2025-01-15",
    "2025-01-19",
    "2025-01-26",
    "2025-02-09",
    "2025-02-09",
    "2025-01-25",
    "2025-02-05",
    "2025-02-16",
    "2025-02-21",
    "2025-02-23",
    "2025-02-23",
    "2025-02-28"
  ),
  Duration_Days = c(1, 4, 7, 14, 14, 3, 15, 7, 5, 4, 9, 5),
  Assignee = c(
    "Project Manager (pm@company.com)",           # Format 1: Name with email in parentheses
    "Business Analyst (ba@company.com)",
    "John Smith (john.smith@company.com)",        # Format 1
    "jane.doe@company.com",                        # Format 2: Email only
    "mike.johnson@company.com",                    # Format 2
    "Sarah Lee (sarah.lee@company.com)",          # Format 1
    "alex.designer@company.com",                   # Format 2
    "QA Team (qa-team@company.com)",              # Format 1
    "Security Team (security@company.com)",        # Format 1
    "DevOps Engineer (devops@company.com)",       # Format 1
    "tech.writer@company.com",                     # Format 2
    "Training Coordinator (training@company.com)"  # Format 1
  ),
  Priority = c(
    "High", "High", "High", "High", "High", "Medium",
    "Medium", "High", "High", "High", "Medium", "Medium"
  ),
  Status = c(
    "To Do", "To Do", "To Do", "To Do", "To Do", "To Do",
    "To Do", "To Do", "To Do", "To Do", "To Do", "To Do"
  ),
  Labels = c(
    "planning,kickoff,meeting",
    "requirements,analysis,documentation",
    "architecture,design,planning",
    "frontend,react,development",
    "backend,api,development",
    "database,postgresql,setup",
    "design,ui,ux,mockups",
    "testing,integration,qa",
    "security,audit,compliance",
    "devops,deployment,cicd",
    "documentation,training,users",
    "training,education,users"
  ),
  stringsAsFactors = FALSE
)

# Save to Excel
filename <- paste0("gantt_template_with_emails_", Sys.Date(), ".xlsx")
write_xlsx(sample_data, filename)

cat("\n========================================\n")
cat("Sample Excel Template Created!\n")
cat("========================================\n\n")
cat("File saved as:", filename, "\n\n")
cat("This template includes:\n")
cat("  ✓ 12 sample tasks\n")
cat("  ✓ Multiple assignee email formats\n")
cat("  ✓ Complete task details\n")
cat("  ✓ Realistic timeline\n")
cat("  ✓ Priority levels\n")
cat("  ✓ Labels/tags\n\n")
cat("Email Formats Demonstrated:\n")
cat("  • Name (email@domain.com) - Recommended format\n")
cat("  • email@domain.com - Simple format\n\n")
cat("You can now:\n")
cat("  1. Open this file in Excel\n")
cat("  2. Modify tasks for your project\n")
cat("  3. Update assignee emails\n")
cat("  4. Upload to the Shiny app\n\n")
cat("========================================\n")

# Also create a minimal template
minimal_data <- data.frame(
  Task_Name = c(
    "Task 1",
    "Task 2", 
    "Task 3"
  ),
  Description = c(
    "Description of task 1",
    "Description of task 2",
    "Description of task 3"
  ),
  Start_Date = c(
    "2025-01-15",
    "2025-01-20",
    "2025-01-25"
  ),
  End_Date = c(
    "2025-01-19",
    "2025-01-24",
    "2025-01-30"
  ),
  Duration_Days = c(5, 5, 6),
  Assignee = c(
    "Person 1 (person1@example.com)",
    "Person 2 (person2@example.com)",
    "Person 3 (person3@example.com)"
  ),
  Priority = c("High", "Medium", "Low"),
  Status = c("To Do", "To Do", "To Do"),
  Labels = c("label1,label2", "label3", "label4,label5"),
  stringsAsFactors = FALSE
)

minimal_filename <- paste0("gantt_minimal_template_", Sys.Date(), ".xlsx")
write_xlsx(minimal_data, minimal_filename)

cat("Minimal template also created:", minimal_filename, "\n")
cat("(Use this as a starting point for your own data)\n\n")