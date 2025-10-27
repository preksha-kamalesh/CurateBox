
# CurateBox: A Personalized Subscription Box Management Platform

CurateBox is a full-stack Flask and MySQL application that serves as an internal admin dashboard for managing a personalized subscription box service.

It allows administrators to manage products, customers, and suppliers, and automatically curates monthly boxes for active subscribers based on their unique preferences. The system includes advanced database features like stored procedures for automation, triggers for inventory management, and complex queries for reporting.

## 🚀 Features

  * **Secure Admin Authentication:** Admin-only access with a hashed password login system.
  * **Dashboard:** A central hub displaying key metrics:
      * Active Subscribers
      * Low-Stock Products
      * Pending Boxes to be Shipped
  * **Product Management (CRUD):**
      * **Create:** Add new products to the inventory.
      * **Read:** View all products, stock levels, and suppliers. Low stock is highlighted.
      * **Update:** Edit product details, stock, and supplier information.
      * **Delete:** Remove products from the database.
  * **Customer Management (CRU):**
      * **Read:** View all registered customers and their subscription status.
      * **Update:** Modify customer details and change subscription status (Active, Paused, Cancelled).
      * **View Preferences:** A dedicated view to see each customer's "Likes" and "Dislikes" (e.g., "Likes Dark Roast", "Dislikes Nuts").
  * **Automated Box Curation:**
      * A "Generate Boxes" button on the dashboard executes a MySQL **Stored Procedure** (`GenerateMonthlyBoxes`).
      * This procedure automatically creates a new `Monthly_Box` for every active subscriber.
      * It intelligently fills the box with products that match the customer's "Likes" and do not match their "Dislikes".
  * **Automatic Inventory Management:**
      * A MySQL **Trigger** (`After_Box_Content_Insert_Update_Stock`) automatically decrements the `stock_quantity` in the `Products` table whenever a new item is added to a `Box_Contents`.
  * **Advanced Reporting:**
      * **Top Shipped Products:** See a list of the most popular items.
      * **Customer Order History:** Search for a customer by name to see all products they have received.
      * **Allergy/Dislike-Safe Products:** View a list of products that have *never* been sent to a customer with a specific dislike (e.g., "Nuts").

## 🛠️ Tech Stack

  * **Backend:** Flask (Python)
  * **Database:** MySQL
  * **Frontend:** Jinja2 (Templating), HTML, CSS, and vanilla JavaScript (for modals)
  * **Python Libraries:** `flask`, `flask-mysqldb`, `hashlib`

## ⚙️ Local Setup and Installation

Follow these steps to run the project on your local machine.

### 1\. Prerequisites

  * Python 3.x
  * `pip` (Python package installer)
  * A running MySQL Server

### 2\. Install Dependencies

1.  Create and activate a virtual environment:

    ```sh
    python -m venv venv
    source venv/bin/activate  # On Windows: .\venv\Scripts\activate
    ```

2.  Install the required Python packages:

    ```sh
    pip install Flask flask-mysqldb
    ```

### 3\. Database Configuration

1.  **IMPORTANT: Fix Admin Password**
    The login system hashes the password `admin` to `8c6976...`. You must update the SQL script to use this hash.

    Open `curateboxdb.sql` and find this line (near the end):

    ```sql
    INSERT INTO `Admins` (`username`, `password_hash`) VALUES ('admin', 'hashed_password_here');
    ```

    Replace it with this line:

    ```sql
    INSERT INTO `Admins` (`username`, `password_hash`) VALUES ('admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918');
    ```

2.  **Run the SQL Script**
    Log in to your MySQL server (e.g., via command line or a GUI like MySQL Workbench) and run the entire `curateboxdb.sql` script. This will:

      * Create the `curatebox_db` schema.
      * Create all 9 tables.
      * Insert all sample data.
      * Create the `GenerateMonthlyBoxes` stored procedure.
      * Create the `After_Box_Content_Insert_Update_Stock` trigger.

### 4\. Application Configuration

1.  Open `app.py`.
2.  Update the MySQL configuration with your database credentials:
    ```python
    # Database config
    app.config['MYSQL_HOST'] = 'localhost'
    app.config['MYSQL_USER'] = 'root'
    app.config['MYSQL_PASSWORD'] = 'yourpassword'  # <-- Change this!
    app.config['MYSQL_DB'] = 'curatebox_db'
    ```
3.  Change the Flask secret key:
    ```python
    app.secret_key = 'enter your secret key here' # <-- Change this!
    ```

### 5\. Run the Application

From your terminal (with the virtual environment activated), run:

```sh
python app.py
```

The application will be running at `http://127.0.0.1:5000`.

## 🖥️ How to Use

1.  Navigate to `http://127.0.0.1:5000`.
2.  Log in using the default credentials:
      * **Username:** `admin`
      * **Password:** `admin`
3.  You will be redirected to the **Dashboard**.
      * To run the monthly curation, click the **"Generate Boxes for [Current Month]"** button. This will call the stored procedure.
4.  Navigate using the navbar:
      * **Products:** Add, edit, or delete products.
      * **Customers:** Edit customer status or click "View Preferences".
      * **Reports:** View the three built-in reports.

## 🗃️ Database Schema

The database `curatebox_db` consists of 9 core tables:

  * `Admins`: Stores hashed login credentials for dashboard admins.
  * `Customers`: Core customer information (name, email, address).
  * `Suppliers`: Information about product suppliers.
  * `Products`: The product inventory, linked to a `supplier_id`.
  * `Subscriptions`: Manages a customer's plan and status (Active, Paused), linked to `customer_id`.
  * `Preference_Options`: A master list of all possible preference traits (e.g., 'Dark Roast', 'Nuts', 'Coffee').
  * `Customers_Preferences`: A junction table linking `Customers` to `Preference_Options` with an `is_like` flag (1 for like, 0 for dislike).
  * `Monthly_Boxes`: A record of each box created for a customer for a specific month.
  * `Box_Contents`: A junction table linking `Products` to `Monthly_Boxes`.

## 📂 Project Structure

```
.
├── app.py                # Main Flask application file
├── curateboxdb.sql       # Full database schema, data, procedures, and triggers
│
├── templates/
│   ├── base.html         # Base template with navigation
│   ├── customers.html    # Manage customers page
│   ├── dashboard.html    # Admin dashboard
│   ├── login.html        # Admin login page
│   ├── preferences.html  # View customer preferences page
│   ├── products.html     # Manage products (CRUD) page
│   └── reports.html      # Reports page
│
└── static/
    └── style.css         #  Stylesheet for all pages
```
