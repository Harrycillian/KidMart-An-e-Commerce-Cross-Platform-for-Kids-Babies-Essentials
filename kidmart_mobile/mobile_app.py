from flask import Flask, render_template, request, redirect, url_for, send_file, make_response, jsonify, session, send_from_directory
from flask_cors import CORS
from datetime import datetime
import mysql.connector
from flask_mail import Mail, Message
import random
import io
from base64 import b64encode
import base64
import logging
import gzip
import json
import time

logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
app.secret_key = 'Hev_Raphy'
CORS(app)

def get_db_connection():
    try:
        return mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="erp_db",
            connect_timeout=60,
            connection_timeout=60,
            pool_name="mypool",
            pool_size=10,
            pool_reset_session=True,
            use_pure=True,
            autocommit=True,
            get_warnings=True,
            raise_on_warnings=True,
            consume_results=True
        )
    except mysql.connector.Error as err:
        print(f"Error connecting to database: {err}")
        raise

@app.route('/mregister_acc', methods=['POST'])
def mregister_acc():
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

    return jsonify({
        'status': 'success',
        'message': 'Account created successfully!'
    })

# @app.route('/courier_register', methods=['POST'])
# def courier_register():
#     lname = request.form['lname']
#     fname = request.form['fname']
#     mname = request.form['mname']

#     name = f"{fname} {mname}. {lname}"

#     email = request.form['email']
#     gender = request.form['gender']
#     country = request.form['country']
#     number = request.form['number']
#     password = request.form['password']

#     region = request.form['region']
#     province = request.form['province']
#     city = request.form['city']
#     brgy = request.form['brgy']

#     conn = None

#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor()

#         sql_user = "INSERT INTO user_info (name, email, gender, country, number, password, position) VALUES (%s, %s, %s, %s, %s, %s, %s)"
#         values_user = (name, email, gender, country, number, password, 'Courier')
#         cursor.execute(sql_user, values_user)

#         user_id = cursor.lastrowid

#         sql_address = "INSERT INTO courier_address (ID, add_name, add_num, region, province, city, brgy) VALUES (%s, %s, %s, %s, %s, %s, %s)"
#         values_address = (user_id, name, number, region, province, city, brgy)
#         cursor.execute(sql_address, values_address)

#         conn.commit()
#     except mysql.connector.Error as err:
#         logging.error(f"Database error: {err}")
#         if conn:
#             conn.rollback()
#     except Exception as e:
#         logging.error(f"Unexpected error: {e}")
#     finally:
#         if conn:
#             if 'cursor' in locals() and cursor is not None:
#                 cursor.close()
#             conn.close()

#     return jsonify({
#         'status': 'success',
#         'message': 'Account created successfully!'
#     })

@app.route('/mcourier_register', methods=['POST'])
def mcourier_register():
    lname = request.form['lname']
    fname = request.form['fname']
    mname = request.form['mname']

    name = f"{fname} {mname}. {lname}"    

    birth = request.form['birth']
    number = request.form['number']
    email = request.form['email']
    country = request.form['country']
    password = request.form['password']
    drivers_license = request.form['drivers_license']

    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    brgy = request.form['brgy']

    drivers_license = drivers_license.read()

    conn = get_db_connection()
    cursor = conn.cursor()

    sql = """INSERT INTO courier_app (name, email, birth, number, country, password, drivers_license) 
        VALUES (%s, %s, %s, %s, %s, %s, %s)"""
    values = (name, email, birth, number, country, password, drivers_license)
    cursor.execute(sql, values)

    user_id = cursor.lastrowid
    print(user_id)

    sql_address = "INSERT INTO buyer_address (ID, add_name, add_num, region, province, city, brgy) VALUES (%s, %s, %s, %s, %s, %s, %s)"
    values_address = (user_id, name, number, region, province, city, brgy)

    try:
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

    return jsonify({
        'status': 'success',
        'message': 'Account created successfully!'
    })

app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'kidmartenterprise@gmail.com' 
app.config['MAIL_PASSWORD'] = 'kstk cpek pqbt mqvy'
mail = Mail(app)

otp_store = {}

@app.route('/mforgot-password/send-otp', methods=['POST'])
def mforgot_otp():
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

@app.route('/mforgot-password/verify-otp', methods=['POST'])
def mverify_otp_and_reset_password():
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

@app.route('/mlogin', methods=['POST'])
def mlogin_acc():
    print("\n=== Login Request ===")
    print(f"Request method: {request.method}")
    print(f"Request headers: {request.headers}")
    print(f"Request data: {request.get_data()}")
    
    try:
        data = request.get_json()
        print(f"Parsed JSON data: {data}")
        
        if not data:
            print("No JSON data received")
            return jsonify({
                'status': 'error',
                'message': 'No data received'
            }), 400
            
        email = data.get('email')
        password = data.get('password')
        
        print(f"Login attempt for email: {email}")

        try:
            conn = get_db_connection()
            cursor = conn.cursor(buffered=True)
        except mysql.connector.Error as err:
            print(f"Database connection error: {err}")
            return jsonify({
                'status': 'error',
                'message': 'Database connection error.'
            }), 500

        try:
            sql = "SELECT ID, position FROM user_info WHERE email = %s AND password = %s"
            cursor.execute(sql, (email, password))
            account = cursor.fetchone()

            if account:
                user_id, position = account
                print(f"Login successful for user {user_id} with position {position}")
                response = jsonify({
                    'status': 'success', 
                    'user_id': user_id, 
                    'position': position,
                    'redirect': '/buyer-home' if position == 'Buyer' else '/courier-home'
                })
                response.headers.add('Access-Control-Allow-Origin', '*')
                return response, 200
            else:
                print("Invalid email or password")
                return jsonify({
                    'status': 'error', 
                    'message': 'Invalid email or password.'
                }), 401

        except mysql.connector.Error as err:
            print(f"Login query error: {err}")
            return jsonify({
                'status': 'error', 
                'message': 'Login failed due to a server error.'
            }), 500

        finally:
            if cursor: cursor.close()
            if conn: conn.close()

    except Exception as e:
        print(f"Unexpected error in login: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': f'Unexpected error: {str(e)}'
        }), 500

@app.route('/api/mbuyer_products/<int:user_id>', methods=['GET'])
def mapi_show_buyer_products(user_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        count_query = "SELECT COUNT(*) as count FROM products"
        cursor.execute(count_query)
        total_count = cursor.fetchone()['count']
        
        query = """
            SELECT p.pid, p.ptitle, MIN(i.image) AS pimage, MIN(v.price) AS pprice, p.seller_ID
            FROM products p
            LEFT JOIN product_images i ON p.pid = i.pid
            LEFT JOIN product_variations v ON p.pid = v.pid
            WHERE p.pid != 30
            GROUP BY p.pid
            ORDER BY RAND()
            LIMIT 26;
        """
        cursor.execute(query)
        products = cursor.fetchall()

        for product in products:
            pimage = product.get('pimage')
            if isinstance(pimage, bytes):
                try:
                    from PIL import Image
                    import io
                    
                    if not pimage:
                        print(f"Empty image data for product {product['pid']}")
                        product['pimage'] = ''
                        continue
                        
                    try:
                        img = Image.open(io.BytesIO(pimage))
                        if img.mode == 'RGBA':
                            img = img.convert('RGB')
                        
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=30, optimize=True)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        if len(img_byte_arr) > 30000:
                            print(f"Image still too large for product {product['pid']}, trying PNG compression")
                            img_byte_arr = io.BytesIO()
                            img.save(img_byte_arr, format='PNG', optimize=True)
                            img_byte_arr = img_byte_arr.getvalue()
                            
                            if len(img_byte_arr) > 30000:
                                print(f"PNG still too large, reducing size further for product {product['pid']}")
                                img = img.resize((50, 50), Image.LANCZOS)
                                img_byte_arr = io.BytesIO()
                                img.save(img_byte_arr, format='PNG', optimize=True)
                                img_byte_arr = img_byte_arr.getvalue()
                        
                        product['pimage'] = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as img_error:
                        print(f"Error processing image for product {product['pid']}: {img_error}")
                        product['pimage'] = ''
                except Exception as e:
                    print(f"Error processing image for product {product['pid']}: {e}")
                    product['pimage'] = ''
            elif pimage is None:
                product['pimage'] = ''
            else:
                product['pimage'] = str(pimage)

        return jsonify({
            'status': 'success',
            'total_count': total_count,
            'products': products
        }), 200

    except Exception as e:
        print("Error in api_show_buyer_products:", e)
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/api/mnotifications/<int:user_id>', methods=['GET'])
def get_notifications(user_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT notif_datetime, bnotif_title, bnotif_text, order_id
            FROM notifications
            WHERE buyer_id = %s
            ORDER BY notif_datetime DESC
        ''', (user_id,))
        notifications = cursor.fetchall()
        return jsonify({'status': 'success', 'notifications': notifications})
    except Exception as e:
        print(f"Error fetching notifications: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/api/mcnotifications/<int:user_id>', methods=['GET'])
def mget_cnotifications(user_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT notif_datetime, cnotif_title, cnotif_text, order_id
            FROM notifications
            WHERE courier_id = %s
            ORDER BY notif_datetime DESC
        ''', (user_id,))
        notifications = cursor.fetchall()
        return jsonify({'status': 'success', 'notifications': notifications})
    except Exception as e:
        print(f"Error fetching notifications: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/api/mbuyer_addresses/<int:user_id>', methods=['GET'])
def mget_buyer_addresses(user_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        query = """
            SELECT add_id, add_name, add_num, region, province, city, brgy
            FROM buyer_address
            WHERE ID = %s
        """
        cursor.execute(query, (user_id,))
        addresses = cursor.fetchall()
        
        return jsonify({
            'status': 'success',
            'addresses': addresses
        }), 200
        
    except Exception as e:
        print(f"Error fetching addresses: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500
        
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-product-details')
def mbuyer_prod():
    try:
        pid = request.args.get('pid')
        user_id = request.args.get('user_id')
        
        if not pid or not user_id:
            return jsonify({
                "status": "error",
                "message": "Missing required parameters"
            }), 400
            
        print(f"Fetching details for product ID: {pid}")
        connection = get_db_connection()

        cursor_product = connection.cursor(dictionary=True, buffered=True)
        cursor_images = connection.cursor(dictionary=True, buffered=True)
        cursor_variations = connection.cursor(dictionary=True, buffered=True)
        cursor_reviews = connection.cursor(dictionary=True, buffered=True)

        check_query = "SELECT pid FROM products WHERE pid = %s"
        cursor_product.execute(check_query, (pid,))
        if not cursor_product.fetchone():
            print(f"Product {pid} not found in database")
            return jsonify({
                "status": "error",
                "message": f"Product with ID {pid} not found"
            }), 404

        product_query = """
        SELECT p.pid, p.ptitle, p.pdesc, p.pcategory, p.trending, p.num_sold, p.seller_ID,
            i.image AS pimage
        FROM products p
        LEFT JOIN product_images i ON p.pid = i.pid
        WHERE p.pid = %s
        """
        cursor_product.execute(product_query, (pid,))
        product = cursor_product.fetchone()
        
        if not product:
            print(f"Could not fetch product details for ID {pid}")
            return jsonify({
                "status": "error",
                "message": f"Could not fetch product details for ID {pid}"
            }), 404

        print(f"Raw product data: {product}")

        if product['pimage']:
            try:
                from PIL import Image
                import io
                
                img = Image.open(io.BytesIO(product['pimage']))
                
                max_size = (200, 200)
                img.thumbnail(max_size, Image.LANCZOS)
                
                img_byte_arr = io.BytesIO()
                img.save(img_byte_arr, format='JPEG', quality=70)
                img_byte_arr = img_byte_arr.getvalue()
                
                product['pimage'] = base64.b64encode(img_byte_arr).decode('utf-8')
                print(f"Successfully processed main product image for ID {pid}")
            except Exception as e:
                print(f"Error processing main product image for ID {pid}: {str(e)}")
                product['pimage'] = ''
        else:
            print(f"No main image found for product ID {pid}")
            product['pimage'] = ''

        image_query = "SELECT image FROM product_images WHERE pid = %s"
        cursor_images.execute(image_query, (pid,))
        images = []
        for img in cursor_images.fetchall():
            if img['image']:
                try:
                    img_data = Image.open(io.BytesIO(img['image']))
                    img_data.thumbnail(max_size, Image.LANCZOS)
                    
                    img_byte_arr = io.BytesIO()
                    img_data.save(img_byte_arr, format='JPEG', quality=100)
                    img_byte_arr = img_byte_arr.getvalue()
                    
                    images.append(base64.b64encode(img_byte_arr).decode('utf-8'))
                    print(f"Successfully processed additional image for product ID {pid}")
                except Exception as e:
                    print(f"Error processing additional image for product ID {pid}: {str(e)}")

        variation_query = "SELECT variation, price, pstocks FROM product_variations WHERE pid = %s"
        cursor_variations.execute(variation_query, (pid,))
        variations = cursor_variations.fetchall() or []
        print(f"Found {len(variations)} variations for product ID {pid}")

        print(f"Processed product data: {product}")
        print(f"Number of images: {len(images)}")
        print(f"Number of variations: {len(variations)}")

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

        response_data = {
            "status": "success",
            "data": {
                "product": product,
                "images": images,
                "variations": variations,
                "user_id": user_id,
                "average": average,
                "reviews": reviews
            }
        }
        
        print(f"Final response data for product ID {pid}: {response_data}")
        return jsonify(response_data)

    except Exception as e:
        print(f"Error in view-product-details for product ID {pid}: {str(e)}")
        print(f"Error type: {type(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

    finally:
        if 'cursor_product' in locals(): cursor_product.close()
        if 'cursor_images' in locals(): cursor_images.close()
        if 'cursor_variations' in locals(): cursor_variations.close()
        if 'cursor_reviews' in locals(): cursor_reviews.close()
        if 'connection' in locals(): connection.close()

@app.route('/madd_to_cart', methods=['POST'])
def madd_to_cart():
    pid = request.form.get('pid')
    selected_price = request.form.get('selected_price')
    selected_variation = request.form.get('selected_variation')
    quantity = request.form.get('quantity')
    user_id = request.form.get('user_id')

    price = float(selected_price)
    quantity = int(quantity)

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
                return jsonify({"status": "error", "message": "Insufficient stock. Maximum available stock: {}.".format(available_stock)})

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

@app.route('/mbuy_now', methods=['POST'])
def mbuy_now():
    data = request.get_json()
    user_id = data['user_id']
    pid = data['pid']
    selected_variation = data['selected_variation']
    try:
        selected_price = float(data['selected_price'])
        quantity = int(data['quantity'])
    except (ValueError, TypeError):
        return jsonify({"status": "error", "message": "Invalid price or quantity."})

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT seller_id FROM products WHERE pid = %s", (pid,))
    seller_result = cursor.fetchone()
    if not seller_result:
        cursor.close()
        connection.close()
        return jsonify({"status": "error", "message": "Product not found."})
    
    seller_id = seller_result[0]

    if quantity <= 0:
        return jsonify({"status": "error", "message": "Quantity must be greater than zero."})
    if quantity > 50:
        return jsonify({"status": "error", "message": "Cannot buy more than 50 items at once."})

    shipping_fee = 40.00
    order_total = (selected_price * quantity) + shipping_fee

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

@app.route('/minstant-checkout/<int:user_id>', methods=['GET'])
def minstant_checkout(user_id):
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

    return jsonify(
        {'merchandise_total': merchandise_total,
            'combined_shipping_fee': combined_shipping_fee,
            'grand_total': grand_total,
            'all_order_items': all_order_items_combined,
            'user_infos': user_infos,
            'order_ids': [order_id],
            'user_id': user_id
        })

@app.route('/mshopping-cart', methods=['GET'])
def mshopping_cart():
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

        for item in cart_items:
            if item['image'] and isinstance(item['image'], bytes):
                try:
                    from PIL import Image
                    import io
                    
                    img = Image.open(io.BytesIO(item['image']))
                    max_size = (200, 200)
                    img.thumbnail(max_size, Image.LANCZOS)
                    
                    img_byte_arr = io.BytesIO()
                    img.save(img_byte_arr, format='JPEG', quality=70)
                    img_byte_arr = img_byte_arr.getvalue()
                    
                    item['image'] = base64.b64encode(img_byte_arr).decode('utf-8')
                except Exception as e:
                    print(f"Error processing image: {e}")
                    item['image'] = ''
            else:
                item['image'] = ''

    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return jsonify({
            "status": "error",
            "message": "Database error occurred"
        }), 500
    except Exception as e:
        print(f"Unexpected error: {e}")
        return jsonify({
            "status": "error",
            "message": "An unexpected error occurred"
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return jsonify({
        "status": "success",
        "data": {
            "cart_items": cart_items,
            "user_id": user_id
        }
    })

@app.route('/mremove-from-cart', methods=['POST'])
def mremove_from_cart():
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

@app.route('/mremove-selected-from-cart', methods=['POST'])
def mremove_selected_from_cart():
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

@app.route('/mcheckout/<int:user_id>', methods=['POST'])
def mcheckout(user_id):
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

@app.route('/mcheckout_page/<int:user_id>', methods=['GET'])
def mcheckout_page(user_id):
    order_ids = request.args.getlist('order_id')
    print("Order IDs:", order_ids)

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    merchandise_total = 0
    combined_shipping_fee = 0
    all_order_items_combined = []

    for order_id in order_ids:
        print(f"Processing order ID: {order_id}")
        
        cursor.execute("""
            SELECT o.order_total, o.shipping_fee
            FROM orders o
            WHERE o.order_id = %s AND o.buyer_id = %s
        """, (order_id, user_id))
        order_details = cursor.fetchone()
        print(f"Order details: {order_details}")

        if order_details:
            merchandise_total += order_details['order_total'] - order_details['shipping_fee']
            combined_shipping_fee += order_details['shipping_fee']

            cursor.execute("""
                SELECT 
                    oi.pid,
                    oi.variation,
                    oi.price,
                    oi.quantity,
                    p.ptitle,
                    oi.cid,
                    (SELECT pi.image FROM product_images pi WHERE pi.pid = oi.pid LIMIT 1) as image
                FROM 
                    order_items oi
                JOIN 
                    products p ON oi.pid = p.pid
                WHERE 
                    oi.order_id = %s
            """, (order_id,))
            order_items = cursor.fetchall()
            print(f"Found {len(order_items)} items for order {order_id}")
            print(f"Raw order items: {order_items}")

            for item in order_items:
                if item['image'] and isinstance(item['image'], bytes):
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(item['image']))
                        max_size = (200, 200)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=70)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        item['image'] = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image for item {item['pid']}: {e}")
                        item['image'] = ''
                else:
                    item['image'] = ''
                
                all_order_items_combined.append(item)

    grand_total = merchandise_total + combined_shipping_fee

    cursor.execute("""
        SELECT add_id, add_name, add_num, brgy, city, province, region
        FROM buyer_address
        WHERE ID = %s
    """, (user_id,))
    user_infos = cursor.fetchall()

    cursor.close()
    db.close()

    response_data = {
        "merchandise_total": merchandise_total,
        "combined_shipping_fee": combined_shipping_fee, 
        "grand_total": grand_total,
        "all_order_items": all_order_items_combined,
        "user_infos": user_infos,
        "order_ids": order_ids,
        "user_id": user_id
    }
    
    print("Final response data:", response_data)
    return jsonify(response_data)

@app.route('/mplace_order', methods=['POST'])
def mplace_order():
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

@app.route('/mview-to-approve-orders/<int:user_id>', methods=['GET'])
def mbuyer_to_approve_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-to-approve-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'To Approve'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'To Approve'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'To Approve'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-to-ship-orders/<int:user_id>', methods=['GET'])
def mbuyer_to_ship_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-to-ship-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'To Ship'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'To Ship'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'To Ship'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-to-receive-orders/<int:user_id>', methods=['GET'])
def mbuyer_to_receive_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-to-receive-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'To Receive'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'To Receive'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'To Receive'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-to-rate-orders/<int:user_id>', methods=['GET'])
def mbuyer_to_rate_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-to-rate-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'To Rate'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'To Rate'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'To Rate'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-completed-orders/<int:user_id>', methods=['GET'])
def mbuyer_completed_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-completed-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'Completed'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'Completed'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'Completed'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mview-cancelled-orders/<int:user_id>', methods=['GET'])
def mbuyer_cancelled_orders(user_id):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-cancelled-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, 'Cancelled'))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status 'Cancelled'")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = 'Cancelled'
                ORDER BY o.order_id DESC;
            """, (user_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

def _fetch_buyer_orders(user_id, status):
    print(f"\n=== New Request ===")
    print(f"Route: /mview-{status.lower()}-orders/{user_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (user_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {user_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Buyer':
                print(f"User {user_id} is not a buyer (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a buyer',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found buyer in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE buyer_id = %s AND status = %s
            """, (user_id, status))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for buyer {user_id} with status {status}")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': f'No {status} orders found for this buyer',
                    'orders': []
                })

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
                WHERE o.buyer_id = %s AND o.status = %s
                ORDER BY o.order_id DESC;
            """, (user_id, status))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'user_id': user_id,
            'status': status
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in _fetch_buyer_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mbcancel-order/<int:order_id>/<int:user_id>', methods=['POST']) 
def mbuyer_cancel_order(order_id, user_id):
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

@app.route('/morder-received/<int:order_id>/<int:user_id>', methods=['POST'])
def morder_received(order_id, user_id):
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

@app.route('/mrate-order', methods=['POST'])
def mrate_order():
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

@app.route('/mcourier-send-otp', methods=['POST'])
def mcourier_send_otp():
    data = request.get_json()
    email = data.get('email')
    
    if not email:
        return jsonify({'error': 'Email is required'}), 400

    otp = str(random.randint(100000, 999999))
    otp_store[email] = otp

    msg = Message('Courier Registration OTP', sender=app.config['MAIL_USERNAME'], recipients=[email])
    msg.body = f"Your OTP code for courier registration is {otp}. Use this code to verify your email."

    try:
        mail.send(msg)
        return jsonify({'message': 'OTP sent successfully! Check your email.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/mcourier-verify-otp', methods=['POST'])
def mcourier_verify_otp():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    
    if not email or not otp:
        return jsonify({'error': 'Email and OTP are required'}), 400

    stored_otp = otp_store.get(email)
    if not stored_otp or stored_otp != otp:
        return jsonify({'error': 'Invalid OTP'}), 400

    otp_store.pop(email, None)
    
    return jsonify({'message': 'OTP verified successfully'})

@app.route('/mcourier-orders/<int:courier_id>', methods=['GET'])
def mcourier_orders(courier_id):
    print(f"\n=== New Request ===")
    print(f"Route: /courier-orders/{courier_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (courier_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {courier_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Courier':
                print(f"User {courier_id} is not a courier (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a courier',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found courier in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE courier_id = %s
            """, (courier_id,))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for courier {courier_id}")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': 'No orders found for this courier',
                    'orders': []
                })

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
                WHERE o.courier_id = %s AND parcel_loc != 'Parcel has been delivered.'
                ORDER BY o.order_id DESC;
            """, (courier_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'courier_id': courier_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in courier_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mdel-orders/<int:courier_id>', methods=['GET'])
def mdel_orders(courier_id):
    print(f"\n=== New Request ===")
    print(f"Route: /courier-orders/{courier_id}")
    print(f"Method: {request.method}")
    print(f"URL: {request.url}")
    
    connection = None
    cursor = None
    
    try:
        try:
            connection = get_db_connection()
            print("Database connection successful")
        except Exception as e:
            print(f"Database connection failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Database connection failed: {str(e)}',
                'orders': []
            }), 500

        cursor = connection.cursor(dictionary=True)

        try:
            cursor.execute("SELECT ID, position FROM user_info WHERE ID = %s", (courier_id,))
            user = cursor.fetchone()
            print(f"User query result: {user}")
            
            if not user:
                print(f"User {courier_id} not found in user_info table")
                return jsonify({
                    'status': 'error',
                    'message': 'User not found',
                    'orders': []
                }), 404

            if user['position'] != 'Courier':
                print(f"User {courier_id} is not a courier (position: {user['position']})")
                return jsonify({
                    'status': 'error',
                    'message': 'User is not a courier',
                    'orders': []
                }), 403
        except Exception as e:
            print(f"User query failed: {str(e)}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to verify user: {str(e)}',
                'orders': []
            }), 500

        print(f"Found courier in database, proceeding with order fetch")

        try:
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM orders 
                WHERE courier_id = %s
            """, (courier_id,))
            count_result = cursor.fetchone()
            print(f"Found {count_result['count']} orders for courier {courier_id}")

            if count_result['count'] == 0:
                return jsonify({
                    'status': 'success',
                    'message': 'No orders found for this courier',
                    'orders': []
                })

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
                WHERE o.courier_id = %s AND parcel_loc = 'Parcel has been delivered.'
                ORDER BY o.order_id DESC;
            """, (courier_id,))

            orders_data = cursor.fetchall()
            print(f"Successfully fetched {len(orders_data)} orders")
        except Exception as e:
            print(f"Orders query failed: {str(e)}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            return jsonify({
                'status': 'error',
                'message': f'Failed to fetch orders: {str(e)}',
                'orders': []
            }), 500

        orders = {}
        for order in orders_data:
            try:
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
                
                pimage = order['pimage']
                if pimage:
                    try:
                        from PIL import Image
                        import io
                        
                        img = Image.open(io.BytesIO(pimage))
                        max_size = (100, 100)
                        img.thumbnail(max_size, Image.LANCZOS)
                        
                        img_byte_arr = io.BytesIO()
                        img.save(img_byte_arr, format='JPEG', quality=50)
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        pimage = base64.b64encode(img_byte_arr).decode('utf-8')
                    except Exception as e:
                        print(f"Error processing image: {e}")
                        pimage = ''
                
                item_data = {
                    'pid': order['pid'],
                    'ptitle': order['ptitle'],
                    'pimage': pimage,
                    'variation': order['variation'],
                    'price': order['price'],
                    'quantity': order['quantity']
                }
                orders[order_id]['items'].append(item_data)
            except Exception as e:
                print(f"Error processing order {order.get('order_id', 'unknown')}: {e}")
                continue

        orders = list(orders.values())
        print(f"Successfully processed {len(orders)} unique orders")

        response_data = {
            'status': 'success',
            'orders': orders,
            'courier_id': courier_id
        }

        return jsonify(response_data)

    except Exception as e:
        print(f"Error in courier_orders: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return jsonify({
            'status': 'error',
            'message': f'Server error: {str(e)}',
            'orders': []
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mcourier-update-status/<int:order_id>', methods=['POST'])
def mcourier_update_status(order_id):
    try:
        data = request.get_json()
        new_status = data.get('status')
        
        if not new_status:
            return jsonify({"status": "error", "message": "Status is required"}), 400

        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            UPDATE orders 
            SET parcel_loc = %s
            WHERE order_id = %s
        """, (new_status, order_id))

        if new_status == "Parcel has been delivered.":
            cursor.execute("""
                UPDATE orders 
                SET status = 'To Rate', order_delivered_datetime = %s
                WHERE order_id = %s
            """, (datetime.now(), order_id))

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
                    'Order Delivered',
                    f'Your order #{order_id} has been delivered. Please rate your experience.'
                ))

        connection.commit()
        return jsonify({
            "status": "success",
            "message": "Order status updated successfully"
        })

    except Exception as e:
        print(f"Error updating order status: {e}")
        return jsonify({
            "status": "error",
            "message": "Failed to update order status"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mcourier-stats/<int:courier_id>', methods=['GET'])
def mcourier_stats(courier_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        today = datetime.now().strftime('%Y-%m-%d')
        cursor.execute("""
            SELECT COUNT(*) as total_deliveries
            FROM orders 
            WHERE courier_id = %s 
            AND DATE(order_delivered_datetime) = %s
            AND status IN ('To Ship', 'To Receive', 'To Rate', 'Delivered')
        """, (courier_id, today))
        total_deliveries = cursor.fetchone()['total_deliveries']

        cursor.execute("""
            SELECT COUNT(*) as pending_deliveries
            FROM orders 
            WHERE courier_id = %s 
            AND status IN ('To Ship', 'To Receive', 'To Rate')
        """, (courier_id,))
        pending_deliveries = cursor.fetchone()['pending_deliveries']

        return jsonify({
            'status': 'success',
            'stats': {
                'total_deliveries': total_deliveries,
                'pending_deliveries': pending_deliveries
            }
        })

    except Exception as e:
        print(f"Error fetching courier stats: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@app.route('/mcourier-profile/<int:courier_id>', methods=['GET'])
def mcourier_profile(courier_id):
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT name, ID 
            FROM user_info 
            WHERE ID = %s AND position = 'Courier'
        """, (courier_id,))
        
        courier = cursor.fetchone()
        
        if not courier:
            return jsonify({
                'status': 'error',
                'message': 'Courier not found'
            }), 404

        return jsonify({
            'status': 'success',
            'profile': {
                'name': courier['name'],
                'courier_id': courier['ID']
            }
        })

    except Exception as e:
        print(f"Error fetching courier profile: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000, threaded=True)