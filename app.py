from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_mysqldb import MySQL
import MySQLdb.cursors
import hashlib
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'enter your secret key here'

# Database config
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'yourpassword'
app.config['MYSQL_DB'] = 'curatebox_db'

mysql = MySQL(app)

# -------------------------------
# LOGIN PAGE
# -------------------------------
@app.route('/', methods=['GET', 'POST'])
def login():
    msg = ''
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        # Hash entered password to match DB
        hashed_pw = hashlib.sha256(password.encode()).hexdigest()

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute('SELECT * FROM Admins WHERE username=%s AND password_hash=%s', (username, hashed_pw))
        account = cursor.fetchone()

        if account:
            session['loggedin'] = True
            session['username'] = account['username']
            return redirect(url_for('dashboard'))
        else:
            msg = 'Invalid username or password!'
    return render_template('login.html', msg=msg)

# -------------------------------
# DASHBOARD PAGE
# -------------------------------
@app.route('/dashboard')
def dashboard():
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

    # These queries assume you have those tables (we’ll add them later)
    cursor.execute("SELECT COUNT(*) AS active FROM Subscriptions WHERE status='Active'")
    active_subs = cursor.fetchone()['active'] if cursor.rowcount else 0

    cursor.execute("SELECT COUNT(*) AS low_stock FROM Products WHERE stock_quantity < 10")
    low_stock = cursor.fetchone()['low_stock'] if cursor.rowcount else 0

    cursor.execute("SELECT COUNT(*) AS pending FROM Monthly_Boxes WHERE shipping_status='Pending'")
    pending_boxes = cursor.fetchone()['pending'] if cursor.rowcount else 0

    month = datetime.now().strftime("%B %Y")

    return render_template('dashboard.html',
                           username=session['username'],
                           active_subs=active_subs,
                           low_stock=low_stock,
                           pending_boxes=pending_boxes,
                           month=month)

# -------------------------------
# PRODUCTS PAGE (READ)
# -------------------------------
@app.route('/products')
def products():
    if 'loggedin' not in session:
        return redirect(url_for('login'))
    
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute("""
        SELECT p.product_id, p.product_name, p.category, p.stock_quantity, s.supplier_name
        FROM Products p
        LEFT JOIN Suppliers s ON p.supplier_id = s.supplier_id
    """)
    products = cursor.fetchall()
    return render_template('products.html', products=products)

# -------------------------------
# ADD NEW PRODUCT
# -------------------------------
@app.route('/add_product', methods=['POST'])
def add_product():
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    name = request.form['product_name']
    category = request.form['category']
    stock = request.form['stock_quantity']
    supplier_id = request.form['supplier_id']

    cursor = mysql.connection.cursor()
    cursor.execute("INSERT INTO Products (product_name, category, stock_quantity, supplier_id) VALUES (%s,%s,%s,%s)",
                   (name, category, stock, supplier_id))
    mysql.connection.commit()
    return redirect(url_for('products'))

# -------------------------------
# EDIT PRODUCT
# -------------------------------
@app.route('/edit_product/<int:product_id>', methods=['POST'])
def edit_product(product_id):
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    name = request.form['product_name']
    category = request.form['category']
    stock = request.form['stock_quantity']
    supplier_id = request.form['supplier_id']

    cursor = mysql.connection.cursor()
    cursor.execute("""
        UPDATE Products
        SET product_name=%s, category=%s, stock_quantity=%s, supplier_id=%s
        WHERE product_id=%s
    """, (name, category, stock, supplier_id, product_id))
    mysql.connection.commit()
    return redirect(url_for('products'))

# -------------------------------
# DELETE PRODUCT
# -------------------------------
@app.route('/delete_product/<int:product_id>', methods=['GET'])
def delete_product(product_id):
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    cursor.execute("DELETE FROM Products WHERE product_id=%s", (product_id,))
    mysql.connection.commit()
    return redirect(url_for('products'))

# -------------------------------
# CUSTOMERS PAGE (READ)
# -------------------------------
@app.route('/customers')
def customers():
    if 'loggedin' not in session:
        return redirect(url_for('login'))
    
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute("""
        SELECT c.customer_id, c.first_name, c.last_name, c.email, s.status AS subscription_status
        FROM Customers c
        LEFT JOIN Subscriptions s ON c.customer_id = s.customer_id
    """)
    customers = cursor.fetchall()
    return render_template('customers.html', customers=customers)

# -------------------------------
# EDIT CUSTOMER
# -------------------------------
@app.route('/edit_customer/<int:customer_id>', methods=['POST'])
def edit_customer(customer_id):
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    first_name = request.form['first_name']
    last_name = request.form['last_name']
    email = request.form['email']
    subscription_status = request.form['subscription_status']

    cursor = mysql.connection.cursor()
    cursor.execute("""
        UPDATE Customers c
        JOIN Subscriptions s ON c.customer_id = s.customer_id
        SET c.first_name=%s, c.last_name=%s, c.email=%s, s.status=%s
        WHERE c.customer_id=%s
    """, (first_name, last_name, email, subscription_status, customer_id))
    mysql.connection.commit()
    return redirect(url_for('customers'))

# -------------------------------
# VIEW CUSTOMER PREFERENCES
# -------------------------------
@app.route('/view_preferences/<int:customer_id>')
def view_preferences(customer_id):
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute("""
        SELECT po.category, po.preference_value, cp.is_like
        FROM Customers_Preferences cp
        JOIN Preference_Options po ON cp.preference_id = po.preference_id
        WHERE cp.customer_id = %s
    """, (customer_id,))
    preferences = cursor.fetchall()

    cursor.execute("SELECT first_name, last_name FROM Customers WHERE customer_id=%s", (customer_id,))
    customer = cursor.fetchone()

    return render_template('preferences.html', preferences=preferences, customer=customer)

# -------------------------------
# REPORTS PAGE
# -------------------------------
@app.route('/reports', methods=['GET', 'POST'])
def reports():
    if 'loggedin' not in session:
        return redirect(url_for('login'))
    
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

    # --- Top Shipped Products ---
    cursor.execute("""
        SELECT p.product_name, COUNT(bc.product_id) AS times_shipped
        FROM Box_Contents bc
        JOIN Products p ON bc.product_id = p.product_id
        GROUP BY p.product_name
        ORDER BY times_shipped DESC
        LIMIT 5
    """)
    top_products = cursor.fetchall()

    # --- Customer Order History ---
    customer_history = []
    search_name = ""
    if request.method == 'POST':
        search_name = request.form['customer_name']
        cursor.execute("""
            SELECT c.first_name, c.last_name, mb.curation_date, p.product_name
            FROM Customers c
            JOIN Monthly_Boxes mb ON c.customer_id = mb.customer_id
            JOIN Box_Contents bc ON mb.box_id = bc.box_id
            JOIN Products p ON bc.product_id = p.product_id
            WHERE c.first_name LIKE %s OR c.last_name LIKE %s
            ORDER BY mb.curation_date DESC
        """, ('%'+search_name+'%', '%'+search_name+'%'))
        customer_history = cursor.fetchall()

    # --- Products safe for Nut allergies ---
    cursor.execute("""
        SELECT product_name, category
        FROM Products
        WHERE product_id NOT IN (
            SELECT DISTINCT bc.product_id
            FROM Box_Contents bc
            JOIN Monthly_Boxes mb ON bc.box_id = mb.box_id
            WHERE mb.customer_id IN (
                SELECT cp.customer_id
                FROM Customers_Preferences cp
                JOIN Preference_Options po ON cp.preference_id = po.preference_id
                WHERE po.preference_value = 'Nuts' AND cp.is_like = 0
            )
        )
    """)
    safe_products = cursor.fetchall()

    return render_template('reports.html', 
                           top_products=top_products, 
                           customer_history=customer_history, 
                           safe_products=safe_products,
                           search_name=search_name)

# -------------------------------
# GENERATE MONTHLY BOXES
# -------------------------------
@app.route('/generate_boxes', methods=['POST'])
def generate_boxes():
    if 'loggedin' not in session:
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    try:
        cursor.execute("CALL GenerateMonthlyBoxes(CURDATE())")
        mysql.connection.commit()
        flash("Monthly boxes generated successfully!", "success")
    except Exception as e:
        flash(f"Error generating boxes: {e}", "danger")
    return redirect(url_for('dashboard'))


# -------------------------------
# LOGOUT
# -------------------------------
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True)
