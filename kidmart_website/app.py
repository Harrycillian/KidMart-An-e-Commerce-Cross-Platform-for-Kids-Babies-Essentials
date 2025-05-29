from flask import Flask, render_template, request, redirect, url_for, send_file, make_response, jsonify
from datetime import datetime
import mysql.connector
from flask_mail import Mail, Message
import random
import io
from base64 import b64encode
import base64
import logging

app = Flask(__name__)

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="erp_db" 
    )

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/forgot-passsword')
def forgot_pass():
    return render_template('forgot_pass.html')

app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'kidmartenterprise@gmail.com' 
app.config['MAIL_PASSWORD'] = 'kstk cpek pqbt mqvy'
mail = Mail(app)

otp_store = {}

@app.route('/forgot-password/send-otp', methods=['POST'])
def forgot_otp():
    email = request.json.get('email')
    otp = str(random.randint(100000, 999999))
    
    otp_store[email] = otp

    msg = Message('Password Reset OTP', sender=app.config['MAIL_USERNAME'], recipients=[email])
    msg.body = f"Your OTP code for password reset is {otp}. Use this code to reset your password."

    try:
        mail.send(msg)
        return jsonify({'message': 'OTP sent successfully! Check your email.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/forgot-password/verify-otp', methods=['POST'])
def verify_otp_and_reset_password():
    email = request.json.get('email')
    otp = request.json.get('otp')
    new_password = request.json.get('new_password')
    confirm_password = request.json.get('confirm_password')
    
    if otp_store.get(email) != otp:
        return jsonify({'error': 'Invalid OTP. Please try again.'}), 400

    if new_password != confirm_password:
        return jsonify({'error': 'Passwords do not match. Please try again.'}), 400

    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute("UPDATE user_info SET password = %s WHERE email = %s", (new_password, email))
    connection.commit()
    cursor.close()
    
    otp_store.pop(email, None)

    return jsonify({'message': 'Password reset successfully! Click OK to proceed to Log In.'})

@app.route('/register_acc', methods=['POST'])
def register_acc():
    lname = request.form['lname']
    fname = request.form['fname']
    mname = request.form['mname']

    name = f"{fname} {mname}. {lname}"

    email = request.form['email']
    gender = request.form['gender']
    country = request.form['country']
    number = request.form['number']
    password = request.form['password']

    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    brgy = request.form['brgy']

    conn = None

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        sql_user = "INSERT INTO user_info (name, email, gender, country, number, password, position) VALUES (%s, %s, %s, %s, %s, %s, %s)"
        values_user = (name, email, gender, country, number, password, 'Buyer')
        cursor.execute(sql_user, values_user)

        user_id = cursor.lastrowid

        sql_address = "INSERT INTO buyer_address (ID, add_name, add_num, region, province, city, brgy) VALUES (%s, %s, %s, %s, %s, %s, %s)"
        values_address = (user_id, name, number, region, province, city, brgy)
        cursor.execute(sql_address, values_address)

        conn.commit()
    except mysql.connector.Error as err:
        logging.error(f"Database error: {err}")
        if conn:
            conn.rollback()
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
    finally:
        if conn:
            if 'cursor' in locals() and cursor is not None:
                cursor.close()
            conn.close()

    return render_template('success.html', name=name, email=email, gender=gender, country=country, number=number)

@app.route('/valid_id/<int:seller_id>')
def get_valid_id(seller_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT valid_id FROM seller_app WHERE ID = %s", (seller_id,))
    valid_id_blob = cursor.fetchone()

    cursor.close()
    conn.close()

    if valid_id_blob:
        valid_id_image = valid_id_blob[0]
        return send_file(io.BytesIO(valid_id_image), mimetype='image/jpeg')
    else:
        return make_response("Image not found", 404)

@app.route('/business_permit/<int:seller_id>')
def get_permit(seller_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT business_permit FROM seller_app WHERE ID = %s", (seller_id,))
    permit_blob = cursor.fetchone()

    cursor.close()
    conn.close()

    if permit_blob:
        permit_image = permit_blob[0]
        return send_file(io.BytesIO(permit_image), mimetype='image/jpeg')
    else:
        return make_response("Image not found", 404)

@app.route('/get_driverlic/<int:courier_id>')
def get_driverlic(courier_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT drivers_license FROM courier_app WHERE ID = %s", (courier_id,))
    drivers_license_blob = cursor.fetchone()

    cursor.close()
    conn.close()

    if drivers_license_blob:
        drivers_license_image = drivers_license_blob[0]
        return send_file(io.BytesIO(drivers_license_image), mimetype='image/jpeg')
    else:
        return make_response("Image not found", 404)

@app.route('/home', methods=['POST'])
def login_acc():
    email = request.form['email']
    password = request.form['password']

    try:
        conn = get_db_connection()
        cursor = conn.cursor(buffered=True)
    except mysql.connector.Error as err:
        print(f"Error connecting to database: {err}")
        return render_template('login.html', error="Database connection error.")

    try:
        sql = "SELECT position FROM user_info WHERE email = %s AND password = %s"
        cursor.execute(sql, (email, password))
        account = cursor.fetchone()

        if account:
            position = account[0]

            if position == 'Buyer':
                sql_id = "SELECT ID FROM user_info WHERE email = %s"
                cursor.execute(sql_id, (email,))
                user_id = cursor.fetchone()

                return show_buyer_products(user_id[0])
            elif position == 'Seller':
                sql_id = "SELECT ID FROM user_info WHERE email = %s"
                cursor.execute(sql_id, (email,))
                seller_id = cursor.fetchone()

                conn.close()
                return show_products(seller_id[0]) 
            elif position == 'Admin':
                return admin_view()
            else:
                return render_template('login.html', error="User position is undefined. Please contact support.")
        else:
            return render_template('login.html', error="Invalid email or password. Please try again.")
        
    except mysql.connector.Error as err:
        print(f"Error during login query execution: {err}")
        return render_template('login.html', error="An error occurred while logging in.")
    
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.route('/signup')
def create_acc():
    return render_template('register.html')

@app.route('/login')
def gotologin():
    return render_template('login.html')

@app.route('/admin')
def admin_view():
    connection = get_db_connection()
    cursor = connection.cursor()

    sql = "SELECT ID, name, email, gender, country, number, position FROM user_info WHERE position = 'Seller' OR position = 'Buyer'"
    cursor.execute(sql)
    users = cursor.fetchall()

    cursor.execute("SELECT COUNT(*) FROM user_info WHERE position = 'Seller'")
    total_sellers = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM user_info WHERE position = 'Buyer'")
    total_buyers = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM user_info WHERE position = 'Courier'")
    total_couriers = cursor.fetchone()[0]

    sql_seller_app = "SELECT ID, name, email, birth, number, income, id_type, valid_id, business_permit FROM seller_app WHERE status='New'"
    cursor.execute(sql_seller_app)
    sellers = cursor.fetchall()

    sql_courier_app = "SELECT ID, name, email, birth, number, drivers_license FROM courier_app WHERE status='New'"
    cursor.execute(sql_courier_app)
    couriers = cursor.fetchall()

    sql_order_summary = """
        SELECT 
            DATE_FORMAT(o.order_delivered_datetime, '%Y/%m/%d') AS order_delivered_datetime,
            o.order_id,
            GROUP_CONCAT(p.ptitle) AS product_titles,
            o.seller_ID,
            o.buyer_id,
            (oi.quantity * oi.price) AS total,
            CAST((oi.quantity * oi.price - (oi.quantity * oi.price * 0.05)) AS DECIMAL(8,2)) AS net_total,
            CAST((oi.quantity * oi.price * 0.05) AS DECIMAL(8,2)) AS admin_com
        FROM 
            orders o
        JOIN 
            order_items oi ON o.order_id = oi.order_id
        JOIN 
            products p ON oi.pid = p.pid
        WHERE
            o.status = 'Completed' OR o.status = 'To Rate'
        GROUP BY 
            o.order_id, oi.item_id;
    """
    cursor.execute(sql_order_summary)
    order_summary = cursor.fetchall()

    sql_order_totals = """
        SELECT 
            COUNT(DISTINCT o.order_id) AS total_orders,
            CAST(SUM(oi.quantity * oi.price) AS DECIMAL(8,2)) AS total_price,
            CAST(SUM((oi.quantity * oi.price - (oi.quantity * oi.price * 0.05))) AS DECIMAL(8,2)) AS total_profit,
            CAST(SUM(oi.quantity * oi.price * 0.05) AS DECIMAL(8,2)) AS total_commission
        FROM 
            orders o
        JOIN 
            order_items oi ON o.order_id = oi.order_id
        WHERE
           o.status = 'Completed' OR o.status = 'To Rate';
    """
    cursor.execute(sql_order_totals)
    order_totals = cursor.fetchone()

    cursor.execute("""
        SELECT ROUND(AVG(oi.quantity * oi.price * 0.05), 2) AS avg_admin_com
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.status = 'Completed' OR o.status = 'To Rate';
    """)
    avg_admin_com = cursor.fetchone()[0]

    cursor.close()
    connection.close()

    return render_template('admin_home.html', users=users, total_sellers=total_sellers, total_buyers=total_buyers, total_couriers=total_couriers, sellers=sellers, couriers=couriers, order_summary=order_summary, total_orders=order_totals[0], total_price=order_totals[1], total_profit=order_totals[2], total_commission=order_totals[3], avg_admin_com=avg_admin_com)

@app.route('/filter_sales')
def filter_sales():
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    connection = get_db_connection()
    cursor = connection.cursor()

    sql_order_summary = """
        SELECT 
            DATE_FORMAT(o.order_delivered_datetime, '%Y/%m/%d') AS order_delivered_datetime,
            o.order_id,
            GROUP_CONCAT(p.ptitle) AS product_titles,
            o.seller_ID,
            o.buyer_id,
            (oi.quantity * oi.price) AS total,
            CAST((oi.quantity * oi.price - (oi.quantity * oi.price * 0.95)) AS DECIMAL(8,2)) AS net_total,
            CAST((oi.quantity * oi.price * 0.05) AS DECIMAL(8,2)) AS admin_com
        FROM 
            orders o
        JOIN 
            order_items oi ON o.order_id = oi.order_id
        JOIN 
            products p ON oi.pid = p.pid
        WHERE
            (o.status = 'Completed' OR o.status = 'To Rate')
            AND o.order_delivered_datetime BETWEEN %s AND %s
        GROUP BY 
            o.order_id, oi.item_id;
    """
    cursor.execute(sql_order_summary, (date_from, date_to))
    order_summary = cursor.fetchall()

    if not order_summary:
        return jsonify({
            'order_summary': [],
            'total_orders': 0,
            'total_price': "0.00",
            'total_profit': "0.00",
            'total_commission': "0.00"
        })

    total_orders = len(order_summary)
    total_price = sum(order[5] for order in order_summary)
    total_profit = sum(order[6] for order in order_summary)
    total_commission = sum(order[7] for order in order_summary)

    return jsonify({'order_summary': order_summary, 'total_orders': total_orders, 'total_price': f"{total_price:.2f}", 'total_profit': f"{total_profit:.2f}", 'total_commission': f"{total_commission:.2f}"})

@app.route('/filter_users', methods=['POST'])
def filter_users():
    filter_type = request.json.get('filter')
    connection = get_db_connection()
    cursor = connection.cursor()

    if filter_type == 'Sellers':
        sql = "SELECT ID, name, email, gender, country, number, position FROM user_info WHERE position = 'Seller'"
    elif filter_type == 'Buyers':
        sql = "SELECT ID, name, email, gender, country, number, position FROM user_info WHERE position = 'Buyer'"
    else:
        sql = "SELECT ID, name, email, gender, country, number, position FROM user_info WHERE position = 'Seller' OR position = 'Buyer'"

    cursor.execute(sql)
    users = cursor.fetchall()
    cursor.close()
    connection.close()

    return jsonify(users)

@app.route('/search_users', methods=['GET'])
def search_users():
    search_term = request.args.get('query', '')

    conn = get_db_connection()
    cursor = conn.cursor()

    sql = """SELECT ID, name, email, gender, country, number, position 
             FROM user_info 
             WHERE (name LIKE %s OR email LIKE %s) 
             AND (position = 'Seller' OR position = 'Buyer')"""
    search_like = f'%{search_term}%'
    cursor.execute(sql, (search_like, search_like))
    users = cursor.fetchall()

    cursor.close()
    conn.close()

    return {"users": users}

@app.route('/search_sellers', methods=['GET'])
def search_sellers():
    search_term = request.args.get('query', '')

    conn = get_db_connection()
    cursor = conn.cursor()

    sql = """
        SELECT ID, name, email, birth, number, income, id_type, valid_id, business_permit
        FROM seller_app 
        WHERE status='New' AND (name LIKE %s OR email LIKE %s) 
        """
    search_like = f'%{search_term}%'
    cursor.execute(sql, (search_like, search_like))
    sellers = cursor.fetchall()

    cursor.close()
    conn.close()

    return {"sellers": sellers}

@app.route('/update_user', methods=['POST'])
def update_user():
    user_id = request.form['user_id']
    name = request.form['name']
    email = request.form['email']
    gender = request.form['gender']
    country = request.form['country']
    number = request.form['number']

    conn = get_db_connection()
    cursor = conn.cursor()

    sql = """UPDATE user_info SET name = %s, email = %s, gender = %s, country = %s, number = %s WHERE ID = %s"""
    values = (name, email, gender, country, number, user_id)

    try:
        cursor.execute(sql, values)
        conn.commit()
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

    return "User updated successfully", 204

@app.route('/fetch_users', methods=['GET'])
def fetch_users():
    connection = get_db_connection()
    cursor = connection.cursor()

    sql = "SELECT ID, name, email, gender, country, number, position FROM user_info WHERE position = 'Seller' OR position = 'Buyer'"
    cursor.execute(sql)
    users = cursor.fetchall()

    cursor.execute("SELECT COUNT(*) FROM user_info WHERE position = 'Seller'")
    total_sellers = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM user_info WHERE position = 'Buyer'")
    total_buyers = cursor.fetchone()[0]

    sql_seller_app = "SELECT ID, name, email, birth, number, income, id_type, valid_id, business_permit FROM seller_app WHERE status='New'"
    cursor.execute(sql_seller_app)
    sellers = cursor.fetchall()

    cursor.close()
    connection.close()

    return {"users": users, 'total_sellers': total_sellers, 'total_buyers': total_buyers, 'sellers': sellers}

@app.route('/delete_user/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    archive_sql = """
        INSERT INTO user_archive (ID, name, email, gender, country, number, password, position, address_name, address_num, region, province, city, brgy, street)
        SELECT ID, name, email, gender, country, number, password, position, address_name, address_num, region, province, city, brgy, street
        FROM user_info
        WHERE ID = %s
    """
    
    delete_sql = "DELETE FROM user_info WHERE ID = %s"

    get_email_sql = "SELECT email FROM user_info WHERE ID = %s"

    try:
        cursor.execute(get_email_sql, (user_id,))
        user_email = cursor.fetchone()
        
        if user_email:
            cursor.execute(archive_sql, (user_id,))
            conn.commit()
            
            cursor.execute(delete_sql, (user_id,))
            conn.commit()

            reason = request.form.get('delreason')
            subject = "Account Suspension Notification"
            body = f"We are writing to inform you that your account on KidMart has been suspended.\n\nReason:\n {reason}\n\nBest regards,/nKidmart Enterprise"

            msg = Message(subject=subject, recipients=[user_email[0]])
            msg.body = body
            mail.send(msg)

    except mysql.connector.Error as err:
        print(f"Error: {err}")
        conn.rollback()
        return "Failed to delete user", 500

    finally:
        cursor.close()
        conn.close()

    return "User moved to archive successfully", 204

@app.route('/become_seller')
def become_seller():
    return render_template('seller_reg_otp.html')

@app.route('/send_otp', methods=['POST'])
def send_otp():
    email = request.form.get('email')
    otp = str(random.randint(100000, 999999))

    msg = Message('Your OTP Code', sender=app.config['MAIL_USERNAME'], recipients=[email])
    msg.body = f"Your OTP code is {otp}. Use this code to complete verification."

    try:
        mail.send(msg)
        return jsonify({'message': 'OTP sent successfully to ' + email + '!', 'otp': otp})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/seller_registration')
def seller_registration():
    return render_template('seller_registration.html')

@app.route('/reg_as_seller', methods=['POST'])
def reg_as_seller():
    lname = request.form['lname']
    fname = request.form['fname']
    mname = request.form['mname']

    name = f"{fname} {mname}. {lname}"    

    birth = request.form['birth']
    number = request.form['number']
    email = request.form['email']
    country = request.form['country']
    password = request.form['password']
    income = request.form['income']
    id_type = request.form['id_type']
    valid_id = request.files['valid_id']
    business_permit = request.files['business_permit']

    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    brgy = request.form['brgy']

    valid_id_data = valid_id.read()
    business_data = business_permit.read()

    conn = get_db_connection()
    cursor = conn.cursor()

    sql = """INSERT INTO seller_app (name, email, birth, number, country, password, income, id_type, valid_id, business_permit) 
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
    values = (name, email, birth, number, country, password, income, id_type, valid_id_data, business_data)
    cursor.execute(sql, values)

    user_id = cursor.lastrowid
    print(user_id)

    sql_address = "INSERT INTO buyer_address (ID, add_name, add_num, region, province, city, brgy) VALUES (%s, %s, %s, %s, %s, %s, %s)"
    values_address = (user_id, name, number, region, province, city, brgy)

    try:
        cursor.execute(sql_address, values_address)
        conn.commit()
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        conn.rollback()
        return render_template('seller_registration.html', error="An error occurred while registering.")
    finally:
        cursor.close()
        conn.close()

    return render_template('seller_registration_success.html')

@app.route('/backtohome')
def backtohome():
    return redirect(url_for('index'))

@app.route('/approve_seller')  
def approve_seller():
    email = request.args.get('email')
    
    if email:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            get_seller_sql = """
            SELECT name, email, country, number, password
            FROM seller_app
            WHERE email = %s
            """
            cursor.execute(get_seller_sql, (email,))
            seller_data = cursor.fetchone()

            if not seller_data:
                return jsonify(success=False, message="Seller not found.")

            name, email, country, number, password = seller_data

            insert_user_info_sql = """
            INSERT INTO user_info (name, email, gender, country, number, password, position)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(insert_user_info_sql, (name, email, 'Male', country, number, password, 'Seller'))

            cursor.execute("SELECT LAST_INSERT_ID()")
            new_user_id = cursor.fetchone()[0]

            update_buyer_address_sql = """
            UPDATE buyer_address
            SET ID = %s
            WHERE ID = (
                SELECT ID FROM seller_app WHERE email = %s
            )
            """
            cursor.execute(update_buyer_address_sql, (new_user_id, email))

            update_seller_app_sql = "UPDATE seller_app SET status = 'Done' WHERE email = %s"
            cursor.execute(update_seller_app_sql, (email,))

            insert_notification_sql = """
            INSERT INTO notifications (notif_datetime, seller_id, snotif_title, snotif_text)
            VALUES (%s, %s, %s, %s)
            """
            notif_datetime = datetime.now()
            snotif_title = "Welcome to KidMart!"
            snotif_text = "Your account has been approved. You are now a seller in KidMart."
            cursor.execute(insert_notification_sql, (notif_datetime, new_user_id, snotif_title, snotif_text))

            subject = "Welcome to KidMart"
            body = f"""Dear {name},\n\nWe are happy to inform you that your account application on KidMart has been approved.\n\nYou are now a part of KidMart Enterprise Co.!\n\nBest regards,\nKidMart Enterprise"""
            msg = Message(subject, sender=app.config['MAIL_USERNAME'], recipients=[email])
            msg.body = body
            mail.send(msg)

            conn.commit()
            cursor.close()
            conn.close()

            return jsonify(success=True)
        except Exception as e:
            print("Error:", e)
            return jsonify(success=False, message="An error occurred.")
    
    return jsonify(success=False, message="Invalid request.")

@app.route('/disapprove_seller', methods=['POST'])
def disapprove_seller():
    data = request.get_json()
    email = data.get('email')
    reason = data.get('reason')
    
    if email and reason:
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            
            update_sql = "UPDATE seller_app SET status = 'Disapproved' WHERE email = %s"
            cursor.execute(update_sql, (email,))
            conn.commit()
            
            subject = "KidMart Application Notice"
            body = f"""Dear valued user,\n\nWe regret to inform you that your account application on KidMart has been disapproved.\nReason: {reason}\n\nBest regards,\nKidMart Enterprise"""
            msg = Message(subject, sender=app.config['MAIL_USERNAME'], recipients=[email])
            msg.body = body
            mail.send(msg)
            
            cursor.close()
            conn.close()
            
            return jsonify(success=True)
        except Exception as e:
            print("Error:", e)
            return jsonify(success=False, message="An error occurred.")
    
    return jsonify(success=False, message="Invalid data provided.")

@app.route('/get_sellers_data')
def get_sellers_data():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    cursor.execute("SELECT ID, name, email, birth, number, income, id_type, valid_id, business_permit FROM seller_app WHERE status='New'")
    sellers = cursor.fetchall()
    connection.close()
    
    return jsonify(sellers=sellers)

@app.route('/approve_courier')  
def approve_courier():
    email = request.args.get('email')
    
    if email:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            get_courier_sql = """
            SELECT name, email, country, number, password
            FROM courier_app
            WHERE email = %s
            """
            cursor.execute(get_courier_sql, (email,))
            courier_data = cursor.fetchone()

            if not courier_data:
                return jsonify(success=False, message="Courier not found.")

            name, email, country, number, password = courier_data

            insert_user_info_sql = """
            INSERT INTO user_info (name, email, gender, country, number, password, position)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(insert_user_info_sql, (name, email, 'Male', country, number, password, 'Courier'))

            cursor.execute("SELECT LAST_INSERT_ID()")
            new_user_id = cursor.fetchone()[0]

            update_courier_address_sql = """
            UPDATE courier_address
            SET ID = %s
            WHERE ID = (
                SELECT ID FROM courier_app WHERE email = %s
            )
            """
            cursor.execute(update_courier_address_sql, (new_user_id, email))

            update_courier_app_sql = "UPDATE courier_app SET status = 'Done' WHERE email = %s"
            cursor.execute(update_courier_app_sql, (email,))

            insert_notification_sql = """
            INSERT INTO notifications (notif_datetime, courier_id, cnotif_title, cnotif_text)
            VALUES (%s, %s, %s, %s)
            """
            notif_datetime = datetime.now()
            snotif_title = "Welcome to KidMart!"
            cnotif_text = "Your account has been approved. You are now a courier in KidMart."
            cursor.execute(insert_notification_sql, (notif_datetime, new_user_id, snotif_title, cnotif_text))

            subject = "Welcome to KidMart"
            body = f"""Dear {name},\n\nWe are happy to inform you that your account application on KidMart has been approved.\n\nYou are now a part of KidMart Enterprise Co.!\n\nBest regards,\nKidMart Enterprise"""
            msg = Message(subject, sender=app.config['MAIL_USERNAME'], recipients=[email])
            msg.body = body
            mail.send(msg)

            conn.commit()
            cursor.close()
            conn.close()

            return jsonify(success=True)
        except Exception as e:
            print("Error:", e)
            return jsonify(success=False, message="An error occurred.")
    
    return jsonify(success=False, message="Invalid request.")

@app.route('/disapprove_courier', methods=['POST'])
def disapprove_courier():
    data = request.get_json()
    email = data.get('email2')
    reason = data.get('reason2')
    
    if email and reason:
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)

            update_sql = "UPDATE courier_app SET status = 'Disapproved' WHERE email = %s"
            cursor.execute(update_sql, (email,))
            conn.commit()
            
            subject = "KidMart Application Notice"
            body = f"""Dear valued user,\n\nWe regret to inform you that your account application on KidMart has been disapproved.\nReason: {reason}\n\nBest regards,\nKidMart Enterprise"""
            msg = Message(subject, sender=app.config['MAIL_USERNAME'], recipients=[email])
            msg.body = body
            mail.send(msg)
            
            cursor.close()
            conn.close()
            
            return jsonify(success=True)
        except Exception as e:
            print("Error:", e)
            return jsonify(success=False, message="An error occurred.")
    
    return jsonify(success=False, message="Invalid data provided.")

@app.route('/get_couriers_data')
def get_couriers_data():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    cursor.execute("SELECT ID, name, email, birth, number, drivers_license FROM courier_app WHERE status='New'")
    couriers = cursor.fetchall()
    connection.close()

    return jsonify(couriers=couriers)

@app.route('/babyclothes&accessories/<int:user_id>')
def bcna(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Baby Clothes & Accessories'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_babyclothes&accessories.html', products=products, user_id=user_id)

@app.route('/educationalmaterials/<int:user_id>')
def edm(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Educational Materials'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_educationalmaterials.html', products=products, user_id=user_id)

@app.route('/nurseryfurniture/<int:user_id>')
def nf(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Nursery Furniture'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_nurseryfurniture.html', products=products, user_id=user_id)

@app.route('/safety&health/<int:user_id>')
def sfh(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Safety & Health'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_safety&health.html', products=products, user_id=user_id)

@app.route('/stroller&gear/<int:user_id>')
def sg(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Stroller & Gear'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_stroller&gear.html', products=products, user_id=user_id)

@app.route('/toys&games/<int:user_id>')
def tg(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           i.image AS pimage, v.price AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    WHERE p.pcategory = 'Toys & Games'
    GROUP BY p.pid
    ORDER BY RAND();
    """
    
    cursor.execute(query)
    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')
    
    cursor.close()
    connection.close()

    return render_template('buyer_toys&games.html', products=products, user_id=user_id)

@app.route('/buyer-address/<int:user_id>')
def buyer_address(user_id):
    query = "SELECT * FROM buyer_address WHERE ID = %s"
    
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    cursor.execute(query, (user_id,))
    
    user_infos = cursor.fetchall()
    
    cursor.close()
    connection.close()

    return render_template('buyer_address.html', user_infos=user_infos, user_id=user_id)

@app.route('/save_buyer_address', methods=['POST'])
def save_buyer_address():
    user_id = request.form.get('user_id')
    add_name = request.form.get('address_name')
    add_num = request.form.get('address_num')
    region = request.form.get('region')
    province = request.form.get('province')
    city = request.form.get('city')
    brgy = request.form.get('brgy')

    query = """
    INSERT INTO buyer_address (ID, add_name, add_num, region, province, city, brgy)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute(query, (user_id, add_name, add_num, region, province, city, brgy))
    
    connection.commit()
    cursor.close()
    connection.close()

    return redirect(url_for('buyer_address', user_id=user_id))

@app.route('/update_address', methods=['POST'])
def update_address():
    user_id = request.form.get('user_idz')
    add_id = request.form.get('add_idz')
    add_name = request.form.get('add_namez')
    add_num = request.form.get('add_numz')
    region = request.form.get('regionz')
    province = request.form.get('provincez')
    city = request.form.get('cityz')
    brgy = request.form.get('brgyz')

    connection = get_db_connection()
    cursor = connection.cursor()
    query = """UPDATE buyer_address 
               SET add_name = %s, add_num = %s, region = %s, province = %s, city = %s, brgy = %s 
               WHERE add_id = %s AND ID = %s"""
    cursor.execute(query, (add_name, add_num, region, province, city, brgy, add_id, user_id))
    connection.commit()

    cursor.execute("SELECT * FROM buyer_address WHERE ID = %s", (user_id,))
    columns = [col[0] for col in cursor.description]
    user_infos = [dict(zip(columns, row)) for row in cursor.fetchall()] 

    cursor.close()
    connection.close()

    return jsonify({'success': True, 'user_infos': user_infos})

@app.route('/show_buyer_products/<int:user_id>')
def show_buyer_products(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    product_query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
           MIN(i.image) AS pimage, MIN(v.price) AS pprice
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN product_variations v ON p.pid = v.pid
    GROUP BY p.pid;
    """
    cursor.execute(product_query)
    products = cursor.fetchall()
    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')

    notif_query = """
    SELECT nid, notif_datetime, bnotif_title, bnotif_text 
    FROM notifications 
    WHERE buyer_id = %s OR position = 'Buyer'
    ORDER BY nid DESC;
    """
    cursor.execute(notif_query, (user_id,))
    notifs = cursor.fetchall()
    for notif in notifs:
        if isinstance(notif['notif_datetime'], datetime):
            notif['notif_datetime'] = notif['notif_datetime'].strftime('%Y/%m/%d %H:%M')

    msg_query = """
        SELECT 
            m.msgid, m.seller_id, u.name AS seller_name,
            CASE
                WHEN m.smsg_text IS NOT NULL THEN m.smsg_text
                ELSE m.bmsg_text
            END AS msg_text, MAX(m.msg_datetime) AS last_msg_time, MAX(m.bmsg_text) AS last_msg
        FROM messages m
        JOIN user_info u ON m.seller_id = u.ID
        WHERE m.buyer_id = %s
        GROUP BY m.seller_id
        ORDER BY last_msg_time DESC;
    """
    cursor.execute(msg_query, (user_id,))
    messages = cursor.fetchall()

    for message in messages:
        if isinstance(message['last_msg_time'], datetime):
            message['last_msg_time'] = message['last_msg_time'].strftime('%Y/%m/%d %H:%M')

    cursor.close()
    connection.close()

    return render_template('buyer_home.html', products=products, user_id=user_id, notifs=notifs, messages=messages)

@app.route('/get_messages')
def get_messages():
    seller_id = request.args.get('seller_id')
    buyer_id = request.args.get('buyer_id')

    query = """
        SELECT bmsg_text, smsg_text, pid
        FROM messages
        WHERE seller_id = %s AND buyer_id = %s
        ORDER BY msg_datetime ASC
    """
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute(query, (seller_id, buyer_id))
    messages = cursor.fetchall()

    formatted_messages = []

    for row in messages:
        bmsg_text, smsg_text, pid = row

        product_details = None
        if pid:
            product_query = """
                SELECT ptitle, 
                       (SELECT pi.image FROM product_images pi WHERE pi.pid = p.pid LIMIT 1) AS pimage
                FROM products p
                WHERE p.pid = %s
            """
            cursor.execute(product_query, (pid,))
            product = cursor.fetchone()

            if product:
                ptitle, pimage = product
                pimage_base64 = None
                if pimage:
                    pimage_base64 = base64.b64encode(pimage).decode('utf-8')

                product_details = {
                    'ptitle': ptitle,
                    'pimage': pimage_base64
                }

        formatted_message = {
            'bmsg_text': bmsg_text,
            'smsg_text': smsg_text,
            'product_details': product_details
        }
        formatted_messages.append(formatted_message)

    cursor.close()
    connection.close()

    return jsonify({'messages': formatted_messages})

@app.route('/pget_messages')
def pget_messages():
    seller_id = request.args.get('seller_ID')
    buyer_id = request.args.get('buyer_id')
    pid = request.args.get('pid')
    print(seller_id, buyer_id, pid)

    connection = get_db_connection()
    cursor = connection.cursor()

    check_query = """
        SELECT 1 FROM messages
        WHERE seller_id = %s AND buyer_id = %s AND pid = %s
        LIMIT 1
    """
    cursor.execute(check_query, (seller_id, buyer_id, pid))
    exists = cursor.fetchone()

    if not exists:
        insert_query = """
            INSERT INTO messages (seller_id, buyer_id, pid, msg_datetime)
            VALUES (%s, %s, %s, %s)
        """
        cursor.execute(insert_query, (seller_id, buyer_id, pid, datetime.now()))
        connection.commit()

    fetch_messages_query = """
        SELECT bmsg_text, smsg_text, NULL AS ptitle, NULL AS pimage, msg_datetime
        FROM messages
        WHERE messages.seller_id = %s AND messages.buyer_id = %s

        UNION ALL

        SELECT NULL AS bmsg_text, NULL AS smsg_text, ptitle, 
            (SELECT pi.image FROM product_images pi WHERE pi.pid = p.pid LIMIT 1) AS pimage, 
            msg_datetime
        FROM messages
        JOIN products p ON messages.pid = p.pid
        WHERE p.seller_ID = %s AND messages.buyer_id = %s AND messages.pid = %s
        ORDER BY msg_datetime ASC;
    """
    cursor.execute(fetch_messages_query, (seller_id, buyer_id, seller_id, buyer_id, pid))
    messages = cursor.fetchall()

    formatted_messages = []
    for row in messages:
        pimage_base64 = None
        if row[3]:
            pimage_base64 = base64.b64encode(row[3]).decode('utf-8')

        formatted_message = {
            'bmsg_text': row[0],
            'smsg_text': row[1],
            'ptitle': row[2],
            'pimage': pimage_base64,
            'msg_datetime': row[4].isoformat()
        }
        formatted_messages.append(formatted_message)

    cursor.close()
    connection.close()

    return jsonify({'messages': formatted_messages})

@app.route('/send_message', methods=['POST'])
def send_message():
    buyer_id = request.form.get('buyer_id')
    seller_id = request.form.get('seller_id')
    bmsg_text = request.form.get('bmsg_text')
    msg_datetime = datetime.now()

    print(buyer_id, seller_id, bmsg_text)
    if not all([buyer_id, seller_id, bmsg_text]):
        return jsonify({'success': False, 'message': 'Missing data'}), 400

    query = """
        INSERT INTO messages (buyer_id, seller_id, bmsg_text, msg_datetime)
        VALUES (%s, %s, %s, %s)
    """

    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(query, (buyer_id, seller_id, bmsg_text, msg_datetime))
        connection.commit()
        return jsonify({'success': True, 'message': 'Message sent successfully'})
    except mysql.connector.Error as e:
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/sget_messages')
def sget_messages():
    seller_id = request.args.get('seller_id')
    buyer_id = request.args.get('buyer_id')

    query = """
        SELECT smsg_text, bmsg_text
        FROM messages
        WHERE seller_id = %s AND buyer_id = %s
        ORDER BY msg_datetime ASC
    """

    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute(query, (seller_id, buyer_id))
    messages = cursor.fetchall()

    formatted_messages = [{'smsg_text': row[0], 'bmsg_text': row[1]} for row in messages]
    return jsonify({'messages': formatted_messages or []})

@app.route('/ssend_message', methods=['POST'])
def ssend_message():
    buyer_id = request.form.get('buyer_id')
    seller_id = request.form.get('seller_id')
    bmsg_text = request.form.get('bmsg_text')
    msg_datetime = datetime.now()

    if not all([buyer_id, seller_id, bmsg_text]):
        return jsonify({'success': False, 'message': 'Missing data'}), 400

    query = """
        INSERT INTO messages (buyer_id, seller_id, smsg_text, msg_datetime)
        VALUES (%s, %s, %s, %s)
    """

    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(query, (buyer_id, seller_id, bmsg_text, msg_datetime))
        connection.commit()
        return jsonify({'success': True, 'message': 'Message sent successfully'})
    except mysql.connector.Error as e:
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/search-products', methods=['POST'])
def search_products():
    search_query = request.json.get('search_query', '').strip()

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT p.pid, p.ptitle, p.pdesc, p.trending, p.num_sold, p.pcategory, 
               i.image AS pimage, v.price AS pprice
        FROM products p
        LEFT JOIN product_images i ON p.pid = i.pid
        LEFT JOIN product_variations v ON p.pid = v.pid
        WHERE p.ptitle LIKE %s
        GROUP BY p.pid;
    """, ('%' + search_query + '%',))

    products = cursor.fetchall()

    for product in products:
        if product['pimage']:
            product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')

    cursor.close()
    connection.close()

    return jsonify({'products': products})

@app.route('/view-my-orders/<int:user_id>', methods=['GET'])
def buyer_orders(user_id):
    status = request.args.get('status', 'To Approve')

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT o.order_id, o.order_datetime, o.order_ship_datetime, o.order_delivered_datetime,
            o.order_total, o.shipping_fee, o.status, o.parcel_loc,
            oi.pid, oi.variation, oi.price, oi.quantity,
            p.ptitle, (SELECT image FROM product_images WHERE pid = p.pid LIMIT 1) AS pimage,
            u.ID AS buyer_id, a.add_name AS buyer_name,
            COALESCE(a.add_num, 'N/A') AS contact_number,
            CONCAT(a.brgy, ', ', a.city, ', ', a.province, ', ', a.region) AS shipping_address,
            pr.feedback_rating, pr.feedback_review
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.pid = p.pid
        JOIN user_info u ON o.buyer_id = u.ID
        JOIN buyer_address a ON o.add_id = a.add_id
        LEFT JOIN product_reviews pr ON pr.oid = o.order_id
        WHERE o.buyer_ID = %s AND o.status = %s
        ORDER BY o.order_id DESC;
    """, (user_id, status))
    
    orders_data = cursor.fetchall()

    orders = {}
    for order in orders_data:
        order_id = order['order_id']
        order['order_datetime'] = order['order_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_datetime'] else None
        order['order_ship_datetime'] = order['order_ship_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_ship_datetime'] else None
        order['order_delivered_datetime'] = order['order_delivered_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_delivered_datetime'] else None
        
        if order_id not in orders:
            orders[order_id] = {
                'order_id': order_id,
                'order_datetime': order['order_datetime'],
                'order_ship_datetime': order['order_ship_datetime'],
                'order_delivered_datetime': order['order_delivered_datetime'],
                'order_total': order['order_total'],
                'shipping_fee': order['shipping_fee'],
                'status': order['status'],
                'parcel_loc': order['parcel_loc'],
                'buyer_name': order['buyer_name'],
                'contact_number': order['contact_number'],
                'shipping_address': order['shipping_address'],
                'items': []
            }
        
        item_data = {
            'pid': order['pid'],
            'ptitle': order['ptitle'],
            'pimage': base64.b64encode(order['pimage']).decode('utf-8') if order['pimage'] else '',
            'variation': order['variation'],
            'price': order['price'],
            'quantity': order['quantity'],
            'feedback_rating': order['feedback_rating'],
            'feedback_review': order['feedback_review']
        }
        orders[order_id]['items'].append(item_data)

    orders = list(orders.values())

    cursor.close()
    connection.close()

    return render_template('buyer_orders.html', orders=orders, user_id=user_id)

@app.route('/view-my-orders/<int:user_id>/filter', methods=['POST'])
def filter_buyer_orders(user_id):
    status = request.json.get('status', 'To Approve')

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT o.order_id, o.order_datetime, o.order_ship_datetime, o.order_delivered_datetime,
            o.order_total, o.shipping_fee, o.status, o.parcel_loc,
            oi.pid, oi.variation, oi.price, oi.quantity,
            p.ptitle, (SELECT image FROM product_images WHERE pid = p.pid LIMIT 1) AS pimage,
            u.ID AS buyer_id, a.add_name AS buyer_name,
            COALESCE(a.add_num, 'N/A') AS contact_number,
            CONCAT(a.brgy, ', ', a.city, ', ', a.province, ', ', a.region) AS shipping_address,
            pr.feedback_rating, pr.feedback_review
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.pid = p.pid
        JOIN user_info u ON o.buyer_id = u.ID
        JOIN buyer_address a ON o.add_id = a.add_id
        LEFT JOIN product_reviews pr ON pr.oid = o.order_id
        WHERE o.buyer_ID = %s AND o.status = %s
        ORDER BY o.order_id DESC;
    """, (user_id, status))
    
    orders_data = cursor.fetchall()

    orders = {}
    for order in orders_data:
        order_id = order['order_id']
        order['order_datetime'] = order['order_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_datetime'] else None
        order['order_ship_datetime'] = order['order_ship_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_ship_datetime'] else None
        order['order_delivered_datetime'] = order['order_delivered_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_delivered_datetime'] else None
        
        if order_id not in orders:
            orders[order_id] = {
                'order_id': order_id,
                'order_datetime': order['order_datetime'],
                'order_ship_datetime': order['order_ship_datetime'],
                'order_delivered_datetime': order['order_delivered_datetime'],
                'order_total': order['order_total'],
                'shipping_fee': order['shipping_fee'],
                'status': order['status'],
                'parcel_loc': order['parcel_loc'],
                'buyer_name': order['buyer_name'],
                'contact_number': order['contact_number'],
                'shipping_address': order['shipping_address'],
                'feedback_rating': order['feedback_rating'],
                'feedback_review': order['feedback_review'],
                'items': []
            }
        
        item_data = {
            'pid': order['pid'],
            'ptitle': order['ptitle'],
            'pimage': base64.b64encode(order['pimage']).decode('utf-8') if order['pimage'] else '',
            'variation': order['variation'],
            'price': order['price'],
            'quantity': order['quantity']
        }
        orders[order_id]['items'].append(item_data)

    orders = list(orders.values())

    cursor.close()
    connection.close()

    return jsonify({'orders': orders})

@app.route('/bcancel-order/<int:order_id>/<int:user_id>', methods=['POST']) 
def buyer_cancel_order(order_id, user_id):
    data = request.get_json()
    reason = data.get('reason')

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        UPDATE orders 
        SET status = 'Cancelled' 
        WHERE order_id = %s AND buyer_id = %s
    """, (order_id, user_id))

    cursor.execute("""
        SELECT pid, variation, quantity 
        FROM order_items 
        WHERE order_id = %s
    """, (order_id,))
    order_items = cursor.fetchall()

    for item in order_items:
        pid = item['pid']
        variation = item['variation']
        quantity = item['quantity']
        
        cursor.execute("""
            UPDATE product_variations 
            SET pstocks = pstocks + %s 
            WHERE pid = %s AND variation = %s
        """, (quantity, pid, variation))

    cursor.execute("""
        INSERT INTO notifications (notif_datetime, order_id, seller_ID, snotif_title, snotif_text) 
        VALUES (%s, %s, 
        (SELECT seller_ID FROM orders WHERE order_id = %s), 
        'Cancel Notice', %s)
    """, (datetime.now(), order_id, order_id, f"Order {order_id} has been cancelled due to {reason}."))

    connection.commit()
    cursor.close()
    connection.close()

    return redirect(url_for('buyer_orders', user_id=user_id, canceled='true'))

@app.route('/order-received/<int:order_id>/<int:user_id>', methods=['POST'])
def order_received(order_id, user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        UPDATE orders 
        SET status = 'To Rate'
        WHERE order_id = %s AND buyer_id = %s
    """, (order_id, user_id))

    cursor.execute("""
        SELECT pid, quantity
        FROM order_items
        WHERE order_id = %s
    """, (order_id,))

    items = cursor.fetchall()
    for item in items:
        cursor.execute("""
            UPDATE products
            SET num_sold = num_sold + %s
            WHERE pid = %s
        """, (item['quantity'], item['pid']))

    cursor.execute("""
        SELECT seller_id FROM orders WHERE order_id = %s
    """, (order_id,))
    order_data = cursor.fetchone()

    seller_id = order_data['seller_id']

    cursor.execute('''
        INSERT INTO notifications (
            notif_datetime, seller_id, snotif_title, snotif_text, order_id
        ) VALUES 
            (%s, %s, %s, %s, %s)
    ''', (
        datetime.now(), 
        seller_id, 
        'Order Complete', 
        f'Order {order_id} has been received by User {user_id}.', 
        order_id
    ))

    connection.commit()

    cursor.close()
    connection.close()

    return jsonify({"status": "success", "message": "Order marked as received!"}), 200

@app.route('/rate-order', methods=['POST'])
def rate_order():
    order_id = request.form.get('order_id')
    rating = request.form.get('rating')
    review = request.form.get('review')

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT oi.pid, p.seller_ID
            FROM order_items oi
            JOIN products p ON oi.pid = p.pid
            WHERE oi.order_id = %s
        """, (order_id,))
        result = cursor.fetchall()

        if not result:
            return jsonify({"success": False, "message": "No products found for this order."}), 400

        for row in result:
            pid, seller_id = row
            cursor.execute("""
                INSERT INTO product_reviews (pid, seller_ID, oid, feedback_rating, feedback_review)
                VALUES (%s, %s, %s, %s, %s)
            """, (pid, seller_id, order_id, rating, review))

        cursor.execute("""
            UPDATE orders
            SET status = 'Completed'
            WHERE order_id = %s
        """, (order_id,))

        conn.commit()

        return jsonify({"success": True, "message": "Review submitted successfully.\nOrder completed!"})

    except mysql.connector.Error as err:
        conn.rollback()
        return jsonify({"success": False, "message": f"Database error: {err}"}), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/view-product-details')
def buyer_prod():
    pid = request.args.get('pid')
    user_id = request.args.get('user_id')
    connection = get_db_connection()

    cursor_product = connection.cursor(dictionary=True, buffered=True)
    cursor_images = connection.cursor(dictionary=True, buffered=True)
    cursor_variations = connection.cursor(dictionary=True, buffered=True)
    cursor_related = connection.cursor(dictionary=True, buffered=True)
    cursor_reviews = connection.cursor(dictionary=True, buffered=True)

    product_query = """
    SELECT p.pid, p.ptitle, p.pdesc, p.pcategory, p.trending, p.num_sold, 
        i.image AS pimage, p.seller_ID, u.name AS seller_name
    FROM products p
    LEFT JOIN product_images i ON p.pid = i.pid
    LEFT JOIN user_info u ON p.seller_ID = u.ID
    WHERE p.pid = %s
    """
    cursor_product.execute(product_query, (pid,))
    product = cursor_product.fetchone()

    if product and product['pimage']:
        product['pimage'] = base64.b64encode(product['pimage']).decode('utf-8')

    image_query = "SELECT image FROM product_images WHERE pid = %s"
    cursor_images.execute(image_query, (pid,))
    images = [base64.b64encode(img['image']).decode('utf-8') for img in cursor_images.fetchall() if img['image']]

    variation_query = "SELECT variation, price, pstocks AS stocks FROM product_variations WHERE pid = %s"
    cursor_variations.execute(variation_query, (pid,))
    variations = cursor_variations.fetchall()

    related_products_query = """
    SELECT p.pid, p.ptitle, p.pdesc, 
        (SELECT MIN(price) FROM product_variations WHERE pid = p.pid) AS price,
        (SELECT image FROM product_images WHERE pid = p.pid LIMIT 1) AS pimage
    FROM products p
    WHERE p.pcategory = %s AND p.pid != %s
    ORDER BY RAND()
    """
    cursor_related.execute(related_products_query, (product['pcategory'], pid))
    related_products = cursor_related.fetchall()

    for related in related_products:
        if related['pimage']:
            related['pimage'] = base64.b64encode(related['pimage']).decode('utf-8')
        else:
            related['pimage'] = 'fallback_image_url'

    review_query = """
    SELECT feedback_rating, feedback_review, review_img 
    FROM product_reviews 
    WHERE pid = %s
    ORDER BY prid DESC
    """
    cursor_reviews.execute(review_query, (pid,))
    reviews = cursor_reviews.fetchall()

    avg_rating_query = """
    SELECT AVG(feedback_rating) AS average_rating
    FROM product_reviews
    WHERE pid = %s
    """
    cursor_reviews.execute(avg_rating_query, (pid,))
    avg_rating_result = cursor_reviews.fetchone()
    average = round(avg_rating_result['average_rating'], 1) if avg_rating_result['average_rating'] else 0

    for review in reviews:
        if review['review_img']:
            review['review_img'] = base64.b64encode(review['review_img']).decode('utf-8')

    cursor_product.close()
    cursor_images.close()
    cursor_variations.close()
    cursor_related.close()
    cursor_reviews.close()
    connection.close()

    return render_template('buyer_prod.html', product=product, images=images, variations=variations, related_products=related_products, reviews=reviews, average=average, user_id=user_id)

@app.route('/add_to_cart', methods=['POST'])
def add_to_cart():
    pid = request.form.get('pid')
    selected_price = request.form.get('selected_price')
    selected_variation = request.form.get('selected_variation')
    quantity = request.form.get('quantity')
    user_id = request.form.get('user_id')

    try:
        price = float(selected_price)
        quantity = int(quantity)
    except (ValueError, TypeError):
        return jsonify({"status": "error", "message": "Invalid price or quantity."})

    if quantity <= 0:
        return jsonify({"status": "error", "message": "Quantity must be greater than zero."})
    if quantity > 50:
        return jsonify({"status": "error", "message": "Cannot add more than 50 items at once."})

    connection = get_db_connection()
    cursor = connection.cursor()

    try:
        stock_query = """
            SELECT pstocks 
            FROM product_variations 
            WHERE pid = %s AND variation = %s
        """
        cursor.execute(stock_query, (pid, selected_variation))
        stock_result = cursor.fetchone()

        if not stock_result:
            return jsonify({"status": "error", "message": "Selected product variation not found."})

        available_stock = stock_result[0]

        if quantity > available_stock:
            return jsonify({"status": "error", "message": f"Insufficient stock. Maximum available stock: {available_stock}."})

        select_query = """
            SELECT cid, quantity 
            FROM buyer_cart 
            WHERE pid = %s AND ID = %s AND variation = %s AND status = 'Cart'
        """
        cursor.execute(select_query, (pid, user_id, selected_variation))
        existing_cart_item = cursor.fetchone()

        if existing_cart_item:
            cart_id = existing_cart_item[0]
            existing_quantity = existing_cart_item[1]
            new_quantity = existing_quantity + quantity

            if new_quantity > available_stock:
                return jsonify({"status": "error", "message": f"Insufficient stock. Maximum available stock: {available_stock}."})
            if new_quantity > 50:
                return jsonify({"status": "error", "message": "Cannot have more than 50 items in the cart for this product."})

            total_unit_price = round(price * new_quantity, 2)

            update_query = """
                UPDATE buyer_cart
                SET quantity = %s, total_unit_price = %s
                WHERE cid = %s
            """
            cursor.execute(update_query, (new_quantity, total_unit_price, cart_id))
            connection.commit()
            return jsonify({"status": "success", "message": "Your cart has been updated successfully!"})
        else:
            total_unit_price = round(price * quantity, 2)
            insert_query = """
                INSERT INTO buyer_cart (ID, pid, quantity, variation, price, total_unit_price)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor.execute(insert_query, (user_id, pid, quantity, selected_variation, price, total_unit_price))
            connection.commit()
            return jsonify({"status": "success", "message": "Product has been successfully added to your cart!"})
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        connection.rollback()
        return jsonify({"status": "error", "message": "Error: Could not add item to cart. Please try again."})
    finally:
        cursor.close()
        connection.close()

@app.route('/buy_now', methods=['POST'])
def buy_now():
    data = request.get_json()
    user_id = data['user_id']
    pid = data['pid']
    selected_variation = data['selected_variation']
    try:
        selected_price = float(data['selected_price'])
        quantity = int(data['quantity'])
    except (ValueError, TypeError):
        return jsonify({"status": "error", "message": "Invalid price or quantity."})

    seller_id = data['seller_ID']

    if quantity <= 0:
        return jsonify({"status": "error", "message": "Quantity must be greater than zero."})
    if quantity > 50:
        return jsonify({"status": "error", "message": "Cannot buy more than 50 items at once."})

    shipping_fee = 40.00
    order_total = (selected_price * quantity) + shipping_fee

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("""
        SELECT pstocks 
        FROM product_variations 
        WHERE pid = %s AND variation = %s
    """, (pid, selected_variation))
    stock_result = cursor.fetchone()
    if not stock_result:
        cursor.close()
        connection.close()
        return jsonify({"status": "error", "message": "Selected product variation not found."})

    available_stock = stock_result[0]
    if quantity > available_stock:
        cursor.close()
        connection.close()
        return jsonify({"status": "error", "message": f"Insufficient stock. Maximum available stock: {available_stock}."})

    cursor.execute(""" 
        INSERT INTO orders (order_datetime, buyer_id, seller_ID, shipping_fee, order_total)
        VALUES (%s, %s, %s, %s, %s)
        """, (datetime.now(), user_id, seller_id, shipping_fee, order_total))

    order_id = cursor.lastrowid

    cursor.execute(""" 
        INSERT INTO order_items (order_id, pid, variation, price, quantity)
        VALUES (%s, %s, %s, %s, %s)
        """, (order_id, pid, selected_variation, selected_price, quantity))

    connection.commit()
    cursor.close()
    connection.close()

    return jsonify({'order_id': order_id})

@app.route('/instant-checkout/<int:user_id>', methods=['GET'])
def instant_checkout(user_id):
    order_id = request.args.get('order_id')
    print("Order ID:", order_id)

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    merchandise_total = 0
    combined_shipping_fee = 0
    all_order_items_combined = []

    if order_id:
        cursor.execute("""
            SELECT o.order_total, o.shipping_fee
            FROM orders o
            WHERE o.order_id = %s AND o.buyer_id = %s
        """, (order_id, user_id))
        order_details = cursor.fetchone()

        if order_details:
            merchandise_total += order_details['order_total'] - order_details['shipping_fee']
            combined_shipping_fee += order_details['shipping_fee']

            cursor.execute("""
                SELECT DISTINCT oi.pid, oi.variation, oi.price, oi.quantity, p.ptitle,
                    (SELECT image FROM product_images WHERE pid = oi.pid LIMIT 1) AS image
                FROM order_items oi
                JOIN products p ON oi.pid = p.pid
                WHERE oi.order_id = %s
            """, (order_id,))
            order_items = cursor.fetchall()
            all_order_items_combined.extend(order_items)

    grand_total = merchandise_total + combined_shipping_fee

    cursor.execute("""
        SELECT add_id, add_name, add_num, brgy, city, province, region
        FROM buyer_address
        WHERE ID = %s
    """, (user_id,))
    user_infos = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template('buyer_payment.html', merchandise_total=merchandise_total, combined_shipping_fee=combined_shipping_fee, grand_total=grand_total, all_order_items=all_order_items_combined, user_infos=user_infos, order_ids=[order_id], user_id=user_id)

@app.template_filter('b64encode')
def b64encode_filter(data):
    return base64.b64encode(data).decode('utf-8') if data else ''

@app.route('/shopping-cart', methods=['GET']) 
def shopping_cart():
    user_id = request.args.get('user_id')
    cart_items = []

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT 
                bc.cid, 
                p.ptitle, 
                (SELECT pi.image FROM product_images pi WHERE pi.pid = p.pid LIMIT 1) AS image,  
                bc.variation, 
                pv.price AS price,  
                bc.quantity AS quantity,
                p.seller_id,
                bc.pid,
                CAST(bc.quantity * pv.price AS DECIMAL(8, 2)) AS total_unit_price
            FROM 
                buyer_cart bc
            JOIN 
                products p ON bc.pid = p.pid
            LEFT JOIN 
                product_variations pv ON bc.variation = pv.variation AND bc.pid = pv.pid
            WHERE 
                bc.ID = %s
                AND bc.status = 'Cart'
            GROUP BY 
                bc.cid, p.ptitle, bc.variation, bc.quantity, p.seller_id
            ORDER BY 
                bc.cid DESC;
        """
        cursor.execute(query, (user_id,))
        cart_items = cursor.fetchall()

    except mysql.connector.Error as err:
        print(f"Error: {err}")
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return render_template('buyer_cart.html', cart_items=cart_items, user_id=user_id)

@app.route('/update-cart', methods=['POST'])
def update_cart():
    data = request.get_json()
    cid = data.get('cid')
    quantity = data.get('quantity')
    user_id = request.args.get('user_id')

    print(f"Received - User ID: {user_id}, Cart ID: {cid}, Quantity: {quantity}")

    if not cid or not user_id or quantity is None:
        return jsonify({'success': False, 'error': 'Missing required data'})

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        price_query = "SELECT price FROM buyer_cart WHERE cid = %s AND ID = %s"
        cursor.execute(price_query, (cid, user_id))
        result = cursor.fetchone()

        if not result:
            return jsonify({'success': False, 'error': 'Cart item not found'})

        price = result['price']
        total_unit_price = float(price) * int(quantity)

        update_query = """
            UPDATE buyer_cart
            SET quantity = %s, total_unit_price = %s
            WHERE cid = %s AND ID = %s;
        """
        cursor.execute(update_query, (quantity, total_unit_price, cid, user_id))
        connection.commit()

        if cursor.rowcount == 0:
            print("No rows updated - possible incorrect cid, user_id, or quantity.")
            return jsonify({'success': False, 'error': 'No rows updated'})
        else:
            print("Database updated successfully")
            return jsonify({'success': True, 'new_total_unit_price': total_unit_price})
    
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return jsonify({'success': False, 'error': str(err)})
    
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/remove-from-cart', methods=['POST'])
def remove_from_cart():
    data = request.get_json()
    cid = data.get('cid')
    user_id = request.args.get('user_id')

    print(f"Updating status of item with cid: {cid} for user_id: {user_id}")

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        update_query = "UPDATE buyer_cart SET status = 'Removed' WHERE cid = %s AND ID = %s"
        cursor.execute(update_query, (cid, user_id))
        connection.commit()

        if cursor.rowcount > 0:
            return jsonify({'success': True})
        else:
            return jsonify({'success': False, 'error': 'No rows updated'})

    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return jsonify({'success': False, 'error': str(err)})
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/remove-selected-from-cart', methods=['POST'])
def remove_selected_from_cart():
    data = request.get_json()
    product_ids = data.get('product_ids') 
    user_id = request.args.get('user_id')

    if not product_ids:
        return jsonify({'success': False, 'error': 'No product IDs provided'})

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        update_query = "UPDATE buyer_cart SET status = 'Removed' WHERE cid IN (%s) AND ID = %s" % (','.join(['%s'] * len(product_ids)), '%s')
        cursor.execute(update_query, product_ids + [user_id])
        connection.commit()

        return jsonify({'success': True})
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return jsonify({'success': False, 'error': str(err)})
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/checkout/<int:user_id>', methods=['POST'])
def checkout(user_id):
    try:
        db = get_db_connection()
        cursor = db.cursor()

        shipping_fee = request.form['shipping_fee']
        selected_items = request.form.get('selected_items', '[]')
        selected_items = eval(selected_items)

        items_by_seller = {}
        for item in selected_items:
            seller_id = item['seller_id']
            if seller_id not in items_by_seller:
                items_by_seller[seller_id] = []
            items_by_seller[seller_id].append(item)

        order_ids = []

        for seller_id, items in items_by_seller.items():
            total_order_amount = sum(float(item['total_unit_price']) for item in items) + float(shipping_fee)

            order_query = """
                INSERT INTO orders (buyer_id, seller_ID, shipping_fee, order_total)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(order_query, (user_id, seller_id, shipping_fee, total_order_amount))
            order_id = cursor.lastrowid
            order_ids.append(order_id)

            order_items_query = """
                INSERT INTO order_items (order_id, pid, cid, variation, price, quantity)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            for item in items:
                cursor.execute(order_items_query, (order_id, item['pid'], item['cid'], item['variation'], item['price'], item['quantity']))

        db.commit()

        return jsonify(success=True, order_ids=order_ids)

    except Exception as e:
        db.rollback()
        print(f"Error during checkout: {e}")
        return jsonify(success=False, message="An error occurred during checkout. Please try again.")
    
    finally:
        cursor.close()
        db.close()

@app.route('/checkout_page/<int:user_id>', methods=['GET'])
def checkout_page(user_id):
    order_ids = request.args.getlist('order_id')
    print("Order IDs:", order_ids)

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    merchandise_total = 0
    combined_shipping_fee = 0
    all_order_items_combined = []

    for order_id in order_ids:
        cursor.execute("""
            SELECT o.order_total, o.shipping_fee
            FROM orders o
            WHERE o.order_id = %s AND o.buyer_id = %s
        """, (order_id, user_id))
        order_details = cursor.fetchone()

        if order_details:
            merchandise_total += order_details['order_total'] - order_details['shipping_fee']
            combined_shipping_fee += order_details['shipping_fee']

            cursor.execute("""
                SELECT 
                    oi.pid, oi.variation, oi.price, oi.quantity, p.ptitle, 
                    pv.vid, oi.cid,
                    (SELECT pi.image FROM product_images pi WHERE pi.pid = oi.pid LIMIT 1) AS image
                FROM 
                    order_items oi
                JOIN 
                    products p ON oi.pid = p.pid
                JOIN 
                    product_variations pv ON oi.variation = pv.variation AND oi.pid = pv.pid
                WHERE 
                    oi.order_id = %s;
            """, (order_id,))
            order_items = cursor.fetchall()
            all_order_items_combined.extend(order_items)

    grand_total = merchandise_total + combined_shipping_fee

    cursor.execute("""
        SELECT add_id, add_name, add_num, brgy, city, province, region
        FROM buyer_address
        WHERE ID = %s
    """, (user_id,))
    user_infos = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template('buyer_payment.html', merchandise_total=merchandise_total, combined_shipping_fee=combined_shipping_fee, grand_total=grand_total, all_order_items=all_order_items_combined, user_infos=user_infos, order_ids=order_ids, user_id=user_id)

@app.route('/apply_voucher', methods=['POST'])
def apply_voucher():
    try:
        order_ids_raw = request.form['order_ids']
        order_ids = [int(order_id) for order_id in order_ids_raw.split(',') if order_id.strip()]
        user_id = request.form['user_id']

        if not order_ids:
            return jsonify(success=False, error="No valid order IDs provided.")

        order_placeholders = ', '.join(['%s'] * len(order_ids))

        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        update_shipping_query = f'''
        UPDATE orders
        SET shipping_fee = 0.00
        WHERE order_id IN ({order_placeholders})
        '''
        cursor.execute(update_shipping_query, tuple(order_ids))

        update_order_total_query = f'''
        UPDATE orders
        SET order_total = order_total - 40
        WHERE order_id IN ({order_placeholders})
        '''
        cursor.execute(update_order_total_query, tuple(order_ids))

        connection.commit()

        merchandise_total = 0
        combined_shipping_fee = 0
        grand_total = 0
        for order_id in order_ids:
            cursor.execute("""
                SELECT o.order_total, o.shipping_fee
                FROM orders o
                WHERE o.order_id = %s
            """, (order_id,))
            order_details = cursor.fetchone()

            if order_details:
                merchandise_total += order_details['order_total'] - order_details['shipping_fee']
                combined_shipping_fee += order_details['shipping_fee']

        grand_total = merchandise_total + combined_shipping_fee

        return jsonify(success=True, message="Voucher applied successfully!", merchandise_total=merchandise_total, combined_shipping_fee=combined_shipping_fee, grand_total=grand_total)

    except Exception as e:
        print("Error updating order details:", e)
        return jsonify(success=False, error="An error occurred while applying the voucher.")
    
    finally:
        cursor.close()
        connection.close()

@app.route('/place_order', methods=['POST'])
def place_order():
    order_datetime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    order_ids_raw = request.form['order_ids']
    order_ids = [int(order_id) for order_id in order_ids_raw.split(',') if order_id.strip()]

    selected_address_id = request.form['selected_address']
    payment_method = request.form['payment']
    shipping_method = request.form['shipping_method']
    user_id = request.form['user_id']
    cart_ids_raw = request.form.getlist('cart_ids')
    viddd_values = request.form.getlist('viddd')
    quantity_values = request.form.getlist('quantity')

    print("Debugging - Order Datetime:", order_datetime)
    print("Debugging - Order IDs:", order_ids)
    print("Debugging - Selected Address ID:", selected_address_id)
    print("Debugging - Payment Method:", payment_method)
    print("Debugging - Shipping Method:", shipping_method)
    print("Debugging - User ID:", user_id)
    print("Debugging - Cart IDs:", cart_ids_raw)
    print("Debugging - viddd values:", viddd_values)
    print("Debugging - Quantity values:", quantity_values)

    if len(viddd_values) != len(quantity_values):
        print("Error: Length mismatch between viddd and quantity.")
        return jsonify({"message": "Data mismatch error."}), 400

    connection = get_db_connection()

    try:
        with connection.cursor(dictionary=True) as cursor:
            order_placeholders = ', '.join(['%s'] * len(order_ids))
            update_query = f'''
            UPDATE orders
            SET order_datetime = %s, add_id = %s, payment_method = %s, shipping_method = %s, status = 'To Approve'
            WHERE order_id IN ({order_placeholders})
            '''
            values = (order_datetime, selected_address_id, payment_method, shipping_method) + tuple(order_ids)
            cursor.execute(update_query, values)
            connection.commit()

        with connection.cursor(dictionary=True) as cursor:
            if cart_ids_raw:
                placeholders = ', '.join(['%s'] * len(cart_ids_raw))
                update_cart_query = f'''
                UPDATE buyer_cart
                SET status = 'Ordered'
                WHERE cid IN ({placeholders})
                '''
                cursor.execute(update_cart_query, tuple(cart_ids_raw))
            connection.commit()

        with connection.cursor(dictionary=True) as cursor:
            for idx, vid in enumerate(viddd_values):
                quantity = int(quantity_values[idx])
                update_stock_query = '''
                    UPDATE product_variations
                    SET pstocks = pstocks - %s
                    WHERE vid = %s
                '''
                cursor.execute(update_stock_query, (quantity, vid))
            connection.commit()

        with connection.cursor(dictionary=True) as cursor:
            for order_id in order_ids:
                cursor.execute("SELECT seller_id FROM orders WHERE order_id = %s", (order_id,))
                seller_data = cursor.fetchone()
                seller_id = seller_data['seller_id'] if seller_data else None

                cursor.execute('''
                    SELECT p.ptitle 
                    FROM order_items oi 
                    JOIN products p ON oi.pid = p.pid 
                    WHERE oi.order_id = %s AND p.seller_ID = %s
                ''', (order_id, seller_id))
                product_titles = [row['ptitle'] for row in cursor.fetchall()]
                product_list_text = ', '.join(product_titles)

                cursor.execute('''
                    INSERT INTO notifications (
                        notif_datetime, buyer_id, seller_id, snotif_title, snotif_text, 
                        bnotif_title, bnotif_text, order_id
                    ) VALUES 
                        (%s, %s, %s, %s, %s, %s, %s, %s)
                ''', (
                    order_datetime, user_id, seller_id, 'You have a new order!', f'User {user_id} just ordered {product_list_text}', 
                    'Order Success', f'Order {order_id} has been successful, and we\'ve notified the seller.', order_id
                ))
            connection.commit()

        return jsonify({"message": "Order has been placed. Thank you for shopping with KidMart!"})

    except Exception as e:
        print("Error during update:", e)
        connection.rollback()
        return jsonify({"message": "An error occurred while placing the order."}), 500

    finally:
        connection.close()

@app.route('/show_products/<int:seller_id>', methods=['GET']) 
def show_products(seller_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT p.*, pi.image, pv.variation, pv.price, pv.pstocks 
        FROM products p
        LEFT JOIN product_images pi ON p.pid = pi.pid
        LEFT JOIN product_variations pv ON p.pid = pv.pid
        WHERE p.seller_ID = %s
    """, (seller_id,))
    
    products = cursor.fetchall()
    
    product_dict = {}
    for product in products:
        pid = product['pid']
        if pid not in product_dict:
            product_dict[pid] = {
                'pid': product['pid'],
                'pcategory': product['pcategory'],
                'ptitle': product['ptitle'],
                'pdesc': product['pdesc'],
                'pimages': [],
                'trending': product['trending'],
                'num_sold': product['num_sold'],
                'variations': {}
            }
        
        if product['image']:
            image_data = base64.b64encode(product['image']).decode('utf-8')
            if image_data not in product_dict[pid]['pimages']:
                product_dict[pid]['pimages'].append(image_data)

        if product['variation']:
            variation_key = product['variation']
            if variation_key not in product_dict[pid]['variations']:
                product_dict[pid]['variations'][variation_key] = {
                    'price': product['price'],
                    'pstocks': product['pstocks']
                }

    products = []
    for product in product_dict.values():
        product['variations'] = [{'name': var, **details} for var, details in product['variations'].items()]
        products.append(product)

    sql_order_summary = """
        SELECT 
            DATE_FORMAT(o.order_delivered_datetime, '%Y/%m/%d') AS order_delivered_datetime,
            o.order_id,
            GROUP_CONCAT(p.ptitle SEPARATOR ', ') AS product_titles,
            o.buyer_id,
            SUM(oi.quantity * oi.price) AS total,
            CAST(SUM(oi.quantity * oi.price * 0.95) AS DECIMAL(8,2)) AS net_total,
            CAST(SUM(oi.quantity * oi.price * 0.05) AS DECIMAL(8,2)) AS admin_com
        FROM 
            orders o
        JOIN 
            order_items oi ON o.order_id = oi.order_id
        JOIN 
            products p ON oi.pid = p.pid
        WHERE
            (o.status = 'Completed' OR o.status = 'To Rate')  AND o.seller_ID = %s
        GROUP BY 
            o.order_id;
    """
    cursor.execute(sql_order_summary, (seller_id,))
    order_summary = cursor.fetchall()

    sql_order_totals = """
        SELECT 
            COUNT(DISTINCT o.order_id) AS total_orders,
            CAST(SUM(oi.quantity * oi.price) AS DECIMAL(8,2)) AS total_price,
            CAST(SUM(oi.quantity * oi.price * 0.95) AS DECIMAL(8,2)) AS total_profit,
            CAST(SUM(oi.quantity * oi.price * 0.05) AS DECIMAL(8,2)) AS total_commission
        FROM 
            orders o
        JOIN 
            order_items oi ON o.order_id = oi.order_id
        WHERE
            (o.status = 'Completed' OR o.status = 'To Rate') AND o.seller_ID = %s;
    """
    cursor.execute(sql_order_totals, (seller_id,))
    order_totals = cursor.fetchone() or {
        "total_orders": 0,
        "total_price": 0.00,
        "total_profit": 0.00,
        "total_commission": 0.00
    }

    notif_query = """
    SELECT nid, notif_datetime, snotif_title, snotif_text 
    FROM notifications 
    WHERE seller_id = %s OR position = 'Seller'
    ORDER BY nid DESC;
    """
    cursor.execute(notif_query, (seller_id,))
    notifs = cursor.fetchall()

    msg_query = """
        SELECT 
            m.msgid, m.buyer_id, u.name AS buyer_name,
            CASE
                WHEN m.bmsg_text IS NOT NULL THEN m.bmsg_text
                ELSE m.smsg_text
            END AS msg_text, MAX(m.msg_datetime) AS last_msg_time, MAX(m.smsg_text) AS last_msg
        FROM messages m
        JOIN user_info u ON m.buyer_id = u.ID
        WHERE m.seller_id = %s
        GROUP BY m.buyer_id
        ORDER BY last_msg_time DESC;
    """
    cursor.execute(msg_query, (seller_id,))
    messages = cursor.fetchall()

    for message in messages:
        if isinstance(message['last_msg_time'], datetime):
            message['last_msg_time'] = message['last_msg_time'].strftime('%Y/%m/%d %H:%M')    

    for notif in notifs:
        if isinstance(notif['notif_datetime'], datetime):
            notif['notif_datetime'] = notif['notif_datetime'].strftime('%Y/%m/%d %H:%M')
            
    cursor.close()
    connection.close()

    return render_template('seller_home.html', products=products, seller_id=seller_id, order_summary=order_summary, total_orders=order_totals["total_orders"], total_price=order_totals["total_price"], total_profit=order_totals["total_profit"], total_commission=order_totals["total_commission"], notifs=notifs, messages=messages)

@app.route('/get_products<int:seller_id>', methods=['GET'])
def get_products(seller_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT p.*, pi.image, pv.variation, pv.price, pv.pstocks 
        FROM products p
        LEFT JOIN product_images pi ON p.pid = pi.pid
        LEFT JOIN product_variations pv ON p.pid = pv.pid
        WHERE p.seller_ID = %s
    """, (seller_id,))
    
    products = cursor.fetchall()
    
    product_dict = {}
    for product in products:
        pid = product['pid']
        if pid not in product_dict:
            product_dict[pid] = {
                'pid': product['pid'],
                'pcategory': product['pcategory'],
                'ptitle': product['ptitle'],
                'pdesc': product['pdesc'],
                'pimages': [],
                'trending': product['trending'],
                'num_sold': product['num_sold'],
                'variations': {}
            }
        
        if product['image']:
            image_data = base64.b64encode(product['image']).decode('utf-8')
            if image_data not in product_dict[pid]['pimages']:
                product_dict[pid]['pimages'].append(image_data)

        if product['variation']:
            variation_key = product['variation']
            if variation_key not in product_dict[pid]['variations']:
                product_dict[pid]['variations'][variation_key] = {
                    'price': product['price'],
                    'pstocks': product['pstocks']
                }

    products = []
    for product in product_dict.values():
        product['variations'] = [{'name': var, **details} for var, details in product['variations'].items()]
        products.append(product)

    cursor.close()
    connection.close()

    return jsonify(products=products)

@app.route('/seller-orders/<int:seller_id>', methods=['GET'])
def seller_orders(seller_id):
    status = request.args.get('status', 'To Approve')

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT o.order_id, o.order_datetime, o.order_ship_datetime, o.order_delivered_datetime,
            o.order_total, o.shipping_fee, o.status, o.parcel_loc,
            oi.pid, oi.variation, oi.price, oi.quantity,
            p.ptitle, (SELECT image FROM product_images WHERE pid = p.pid LIMIT 1) AS pimage, u.ID AS buyer_id, 
            a.add_name AS buyer_name, COALESCE(a.add_num, 'N/A') AS contact_number,
            CONCAT(a.brgy, ', ', a.city, ', ', a.province, ', ', a.region) AS shipping_address,
            pr.feedback_rating, pr.feedback_review
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.pid = p.pid
        JOIN user_info u ON o.buyer_id = u.ID
        JOIN buyer_address a ON o.add_id = a.add_id
        LEFT JOIN product_reviews pr ON pr.oid = o.order_id
        WHERE o.seller_ID = %s AND o.status = %s
        ORDER BY o.order_id DESC;
    """, (seller_id, status))

    orders_data = cursor.fetchall()

    orders = {}
    for order in orders_data:
        order_id = order['order_id']
        order['order_datetime'] = order['order_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_datetime'] else None
        order['order_ship_datetime'] = order['order_ship_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_ship_datetime'] else None
        order['order_delivered_datetime'] = order['order_delivered_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_delivered_datetime'] else None
        
        if order_id not in orders:
            orders[order_id] = {
                'order_id': order_id,
                'order_datetime': order['order_datetime'],
                'order_ship_datetime': order['order_ship_datetime'],
                'order_delivered_datetime': order['order_delivered_datetime'],
                'order_total': order['order_total'],
                'shipping_fee': order['shipping_fee'],
                'status': order['status'],
                'parcel_loc': order['parcel_loc'],
                'buyer_name': order['buyer_name'],
                'contact_number': order['contact_number'],
                'shipping_address': order['shipping_address'],
                'feedback_rating': order['feedback_rating'],
                'feedback_review': order['feedback_review'],
                'items': []
            }
        
        item_data = {
            'pid': order['pid'],
            'ptitle': order['ptitle'],
            'pimage': base64.b64encode(order['pimage']).decode('utf-8') if order['pimage'] else '',
            'variation': order['variation'],
            'price': order['price'],
            'quantity': order['quantity']
        }
        orders[order_id]['items'].append(item_data)

    orders = list(orders.values())

    cursor.close()
    connection.close()

    return render_template('seller_orders.html', seller_id=seller_id, orders=orders)

@app.route('/view-orders/<int:seller_id>/filter', methods=['POST'])
def filter_seller_orders(seller_id):
    status = request.json.get('status', 'To Approve')

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT o.order_id, o.order_datetime, o.order_ship_datetime, o.order_delivered_datetime,
            o.order_total, o.shipping_fee, o.status, o.parcel_loc,
            oi.pid, oi.variation, oi.price, oi.quantity,
            p.ptitle, (SELECT image FROM product_images WHERE pid = p.pid LIMIT 1) AS pimage, u.ID AS buyer_id, 
            a.add_name AS buyer_name, COALESCE(a.add_num, 'N/A') AS contact_number,
            CONCAT(a.brgy, ', ', a.city, ', ', a.province, ', ', a.region) AS shipping_address,
            pr.feedback_rating, pr.feedback_review
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.pid = p.pid
        JOIN user_info u ON o.buyer_id = u.ID
        JOIN buyer_address a ON o.add_id = a.add_id
        LEFT JOIN product_reviews pr ON pr.oid = o.order_id
        WHERE o.seller_ID = %s AND o.status = %s
        ORDER BY o.order_id DESC;
    """, (seller_id, status))
    
    orders_data = cursor.fetchall()

    orders = {}
    for order in orders_data:
        order_id = order['order_id']
        order['order_datetime'] = order['order_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_datetime'] else None
        order['order_ship_datetime'] = order['order_ship_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_ship_datetime'] else None
        order['order_delivered_datetime'] = order['order_delivered_datetime'].strftime('%m/%d/%Y %H:%M') if order['order_delivered_datetime'] else None
        
        if order_id not in orders:
            orders[order_id] = {
                'order_id': order_id,
                'order_datetime': order['order_datetime'],
                'order_ship_datetime': order['order_ship_datetime'],
                'order_delivered_datetime': order['order_delivered_datetime'],
                'order_total': order['order_total'],
                'shipping_fee': order['shipping_fee'],
                'status': order['status'],
                'parcel_loc': order['parcel_loc'],
                'buyer_name': order['buyer_name'],
                'contact_number': order['contact_number'],
                'shipping_address': order['shipping_address'],
                'feedback_rating': order['feedback_rating'],
                'feedback_review': order['feedback_review'],
                'items': []
            }
        
        item_data = {
            'pid': order['pid'],
            'ptitle': order['ptitle'],
            'pimage': base64.b64encode(order['pimage']).decode('utf-8') if order['pimage'] else '',
            'variation': order['variation'],
            'price': order['price'],
            'quantity': order['quantity']
        }
        orders[order_id]['items'].append(item_data)

    orders = list(orders.values())

    cursor.close()
    connection.close()

    return jsonify({'orders': orders})

@app.route('/approve-order/<int:order_id>/<int:seller_id>', methods=['POST'])
def seller_approve_order(order_id, seller_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(""" 
            UPDATE orders 
            SET status = 'To Ship', parcel_loc = 'Seller is preparing to ship your parcel.'
            WHERE order_id = %s AND seller_ID = %s
        """, (order_id, seller_id))
        
        cursor.execute("SELECT buyer_id FROM orders WHERE order_id = %s", (order_id,))
        buyer = cursor.fetchone()
        if not buyer:
            return jsonify({"status": "error", "message": "Order or buyer not found"}), 404
        buyer_id = buyer['buyer_id']

        notif_datetime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        bnotif_title = 'Order Approved'
        bnotif_text = f'Order {order_id} has been confirmed by the seller. Kindly wait for your shipment.'
        
        cursor.execute("""
            INSERT INTO notifications (notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text)
            VALUES (%s, %s, %s, %s, %s)
        """, (notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text))
        
        connection.commit()

        return jsonify({"status": "success", "message": "Order approved successfully!"}), 200

    except Exception as e:
        connection.rollback()
        print("Error:", e)
        return jsonify({"status": "error", "message": "An error occurred while approving the order."}), 500

    finally:
        cursor.close()
        connection.close()

@app.route('/cancel-order/<int:order_id>/<int:seller_id>', methods=['POST'])
def seller_cancel_order(order_id, seller_id):
    data = request.get_json()
    reason = data.get('reason')
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        UPDATE orders 
        SET status = 'Cancelled' 
        WHERE order_id = %s AND seller_ID = %s
    """, (order_id, seller_id))

    cursor.execute("""
        SELECT pid, variation, quantity 
        FROM order_items 
        WHERE order_id = %s
    """, (order_id,))
    order_items = cursor.fetchall()

    for item in order_items:
        pid = item['pid']
        variation = item['variation']
        quantity = item['quantity']
        
        cursor.execute("""
            UPDATE product_variations 
            SET pstocks = pstocks + %s 
            WHERE pid = %s AND variation = %s
        """, (quantity, pid, variation))

    cursor.execute("""
        INSERT INTO notifications (notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text) 
        VALUES (%s, %s, 
        (SELECT buyer_id FROM orders WHERE order_id = %s), 
        'Cancel Notice', 
        %s)
    """, (datetime.now(), order_id, order_id, f"Order {order_id} has been cancelled due to {reason}."))

    connection.commit()
    cursor.close()
    connection.close()

    return jsonify({"status": "success", "message": f"Order {order_id} cancelled successfully!"}), 200

@app.route('/mark-as-shipped/<int:order_id>/<int:seller_id>', methods=['POST'])
def seller_mark_shipped(order_id, seller_id):
    try:
        courier_id = request.form.get('courier_id')
        
        if not courier_id:
            return jsonify({"status": "error", "message": "Courier ID is required"}), 400

        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT ID FROM user_info 
            WHERE ID = %s AND position = 'Courier'
        """, (courier_id,))
        courier = cursor.fetchone()
        
        if not courier:
            return jsonify({"status": "error", "message": "Invalid or unapproved courier"}), 400

        cursor.execute("""
            UPDATE orders 
            SET status = 'To Receive', 
                courier_id = %s,
                order_ship_datetime = %s,
                parcel_loc = 'Parcel has arrived at sorting facility.'
            WHERE order_id = %s AND seller_id = %s
        """, (courier_id, datetime.now(), order_id, seller_id))

        cursor.execute("SELECT buyer_id FROM orders WHERE order_id = %s", (order_id,))
        buyer = cursor.fetchone()
        
        if buyer:
            cursor.execute("""
                INSERT INTO notifications (
                    notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                datetime.now(),
                order_id,
                buyer['buyer_id'],
                'Order Shipped',
                f'Your order #{order_id} has been shipped and is now in transit.'
            ))

            cursor.execute("""
                INSERT INTO notifications (
                    notif_datetime, order_id, courier_id, cnotif_title, cnotif_text
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                datetime.now(),
                order_id,
                courier_id,
                'New Delivery Assignment',
                f'You have been assigned to deliver order #{order_id}.'
            ))

        connection.commit()
        return jsonify({
            "status": "success",
            "message": "Order marked as shipped and courier assigned successfully"
        })

    except Exception as e:
        print(f"Error marking order as shipped: {e}")
        return jsonify({
            "status": "error",
            "message": "Failed to mark order as shipped"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/get-approved-couriers', methods=['GET'])
def get_approved_couriers():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT ID, name, number 
            FROM user_info 
            WHERE position = 'Courier'
        """)
        couriers = cursor.fetchall()

        return jsonify({
            "status": "success",
            "couriers": couriers
        })

    except Exception as e:
        print(f"Error fetching approved couriers: {e}")
        return jsonify({
            "status": "error",
            "message": "Failed to fetch approved couriers"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/update-order-status/<int:order_id>', methods=['POST'])
def update_order_status(order_id):
    data = request.get_json()
    selected_status = data.get('status')

    if not selected_status:
        return jsonify({'status': 'error', 'message': 'Invalid status selected.'}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        query = "UPDATE orders SET parcel_loc = %s WHERE order_id = %s"
        cursor.execute(query, (selected_status, order_id))
        conn.commit()

        if cursor.rowcount > 0:
            response = {'status': 'success', 'message': 'Order status updated successfully.'}
            
            if selected_status == 'Parcel has been delivered.':
                cursor.execute("SELECT buyer_id, seller_ID FROM orders WHERE order_id = %s", (order_id,))
                order_info = cursor.fetchone()
                
                if order_info:
                    buyer_id = order_info['buyer_id']
                    seller_id = order_info['seller_ID']
                    
                    notif_datetime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    bnotif_title = 'Confirm Receipt'
                    bnotif_text = f'Parcel for order {order_id} has been delivered. Kindly provide feedback for the seller. Thank you for shopping with KidMart!'
                    
                    cursor.execute("""
                        INSERT INTO notifications (notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (notif_datetime, order_id, buyer_id, bnotif_title, bnotif_text))
                    
                    cursor.execute("""
                        UPDATE orders 
                        SET order_delivered_datetime = %s
                        WHERE order_id = %s AND seller_ID = %s
                    """, (datetime.now(), order_id, seller_id))
                    
                    conn.commit()

        else:
            response = {'status': 'error', 'message': 'Order status update failed. Order not found.'}

    except mysql.connector.Error as err:
        response = {'status': 'error', 'message': f'Error updating order status: {err}'}

    finally:
        cursor.close()
        conn.close()

    return jsonify(response)

@app.route('/get-review/<int:order_id>', methods=['GET'])
def get_review(order_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    query = """
    SELECT feedback_rating, feedback_review
    FROM product_reviews
    WHERE oid = %s
    """
    cursor.execute(query, (order_id,))
    review = cursor.fetchone()
    cursor.close()
    connection.close()

    if review:
        return jsonify({'success': True, 'review': review})
    else:
        return jsonify({'success': False, 'message': 'No review found'})
    
@app.route('/add_product', methods=['POST']) 
def add_product():
    pcategory = request.form['product_ctgrs']
    ptitle = request.form['product_title']
    pdesc = request.form['product_desc']
    seller_id = request.form['seller_id']

    pimages = request.files.getlist('product_images')

    conn = get_db_connection()
    cursor = conn.cursor()

    sql_product = """INSERT INTO products (seller_ID, pcategory, ptitle, pdesc)
                     VALUES (%s, %s, %s, %s)"""
    product_values = (seller_id, pcategory, ptitle, pdesc)
    cursor.execute(sql_product, product_values)
    
    last_product_id = cursor.lastrowid

    for pimage in pimages:
        pimage_data = pimage.read()
        sql_image = """INSERT INTO product_images (pid, image)
                       VALUES (%s, %s)"""
        cursor.execute(sql_image, (last_product_id, pimage_data))

    product_variations = request.form.getlist('product_variation[]')
    variation_prices = request.form.getlist('variation_price[]')
    variation_stocks = request.form.getlist('variation_stocks[]')

    for variation, price, stock in zip(product_variations, variation_prices, variation_stocks):
        cursor.execute("INSERT INTO product_variations (pid, variation, price, pstocks) VALUES (%s, %s, %s, %s)", (last_product_id, variation, price, stock))

    conn.commit()
    cursor.close()
    conn.close()
    
    return redirect(url_for('show_products', seller_id=seller_id, success=1))

@app.route('/get_product/<int:pid>', methods=['GET'])
def get_product(pid):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("SELECT ptitle, pdesc FROM products WHERE pid = %s", (pid,))
    product = cursor.fetchone()

    cursor.execute("SELECT vid, variation, price, pstocks FROM product_variations WHERE pid = %s", (pid,))
    variations = cursor.fetchall()

    cursor.execute("SELECT imgid, image FROM product_images WHERE pid = %s", (pid,))
    images = cursor.fetchall()

    cursor.close()

    return jsonify({
        'ptitle': product['ptitle'],
        'pdesc': product['pdesc'],
        'variations': [{'vid': v['vid'], 'name': v['variation'], 'price': v['price'], 'pstocks': v['pstocks']} for v in variations],
        'images': [{'imgid': img['imgid'], 'base64': base64.b64encode(img['image']).decode('utf-8')} for img in images]
    })

@app.route('/remove_image/<int:imgid>', methods=['DELETE'])
def remove_image(imgid):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("DELETE FROM product_images WHERE imgid = %s", (imgid,))
    connection.commit()

    cursor.close()
    return jsonify(success=True), 200

@app.route('/remove_variation/<int:vid>', methods=['DELETE'])
def remove_variation(vid):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("DELETE FROM product_variations WHERE vid = %s", (vid,))
    connection.commit()

    cursor.close()
    return jsonify(success=True), 200

@app.route('/get_variations/<int:pid>', methods=['GET'])
def get_variations(pid):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("SELECT vid, variation, price, pstocks FROM product_variations WHERE pid = %s", (pid,))
    variations = cursor.fetchall()
    cursor.close()

    return jsonify(variations)

@app.route('/edit_product', methods=['POST'])
def edit_product():
    pid = request.form.get('pid')
    ptitle = request.form.get('ptitle')
    pdesc = request.form.get('pdesc')

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("UPDATE products SET ptitle = %s, pdesc = %s WHERE pid = %s", (ptitle, pdesc, pid))

    variation_ids = request.form.getlist('variation_id')
    variations = request.form.getlist('variation_name')
    prices = request.form.getlist('variation_price')
    stocks = request.form.getlist('variation_stocks')

    for vid, name, price, stock in zip(variation_ids, variations, prices, stocks):
        if vid:
            cursor.execute("""
                UPDATE product_variations 
                SET variation = %s, price = %s, pstocks = %s 
                WHERE pid = %s AND vid = %s
            """, (name, price, stock, pid, vid))
        else:
            cursor.execute("""
                INSERT INTO product_variations (pid, variation, price, pstocks) 
                VALUES (%s, %s, %s, %s)
            """, (pid, name, price, stock))

    if 'images' in request.files:
        images = request.files.getlist('images')
        for image in images:
            if image and image.filename:
                cursor.execute("""
                    INSERT INTO product_images (pid, image) 
                    VALUES (%s, %s)
                """, (pid, image.read()))

    connection.commit()
    cursor.close()

    return jsonify({'status': 'success'})

@app.route('/delete_product/<int:pid>', methods=['DELETE'])
def delete_product(pid):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT * FROM products WHERE pid = %s", (pid,))
    product = cursor.fetchone()

    if product:
        cursor.execute("""
            INSERT INTO product_archive (pid, seller_ID, pcategory, ptitle, pdesc, pimage, trending, num_sold) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (product['pid'], product['seller_ID'], product['pcategory'], product['ptitle'], 
              product['pdesc'], product['pimage'], product['trending'], product['num_sold']))

        cursor.execute("DELETE FROM products WHERE pid = %s", (pid,))
        connection.commit()

    cursor.close()
    return jsonify(success=True)

if __name__ == "__main__":
    app.run(debug=True)