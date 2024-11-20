# SysAdminSorcery 🪄

Welcome to **SysAdminSorcery**! This repository is a curated collection of PowerShell scripts aimed at **empowering system administrators** and **help desk professionals** to resolve issues faster and automate repetitive tasks. Whether you're streamlining user management, troubleshooting systems, or implementing automation, SysAdminSorcery has something for you.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Features
- **Time-Saving Scripts:** Optimize and speed up help desk workflows.
- **Automation Magic:** Reduce repetitive tasks with powerful automation tools.
- **Customizable Solutions:** Adaptable scripts to meet your organization's unique needs.
- **Open Source:** A community-driven project designed for collaboration and improvement.

## Installation

Getting started is simple! Follow these steps:

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/Ogyiesworld/SysAdminSorcery.git
    ```

2. **Navigate to the Directory:**
   
    ```bash
    cd SysAdminSorcery
    ```

3. **Set Execution Policy:** Ensure PowerShell can execute scripts:

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

   (Run as Administrator if required.)

## Usage

Run scripts directly from the PowerShell terminal. Here's how:

1. **Navigate to the script's directory:**

    ```powershell
    cd path-to-script-directory
    ```

2. **Execute the script:**

    ```powershell
    .\example-script.ps1
    ```

   Replace `example-script.ps1` with the name of the script you want to run.

3. **Follow the script prompts** (if applicable).

### Example

For user management:

```powershell
.\Add-NewUser.ps1 -UserName "JohnDoe" -Email "johndoe@example.com"
```

Check each script’s inline comments or documentation for parameters and examples.

## Contributing

Contributions are the lifeblood of SysAdminSorcery! If you have ideas, bug fixes, or new scripts to share, here's how you can contribute:

1. **Fork the Repository:** Click the "Fork" button on the top-right corner of this repository.

2. **Create a Branch:**

    ```bash
    git checkout -b feature/your-feature-name
    ```

3. **Make Your Changes:** Add or improve scripts, update documentation, or fix issues.

4. **Commit Your Changes:** Write clear, descriptive commit messages:

    ```bash
    git commit -m "Add feature: brief description of your changes"
    ```

5. **Push Changes to Your Fork:**

    ```bash
    git push origin feature/your-feature-name
    ```

6. **Submit a Pull Request:** Open a pull request to the main repository with details about your contribution.

   I'm relatively new to Git, especially in the context of public repositories and contributions. I would love to work with anyone who wants to improve this collection and assist me. Together, we can make SysAdminSorcery even better!

   We’ll review your PR and work with you to get it merged!

## License

This project is licensed under the GNU General Public License v3.0.
