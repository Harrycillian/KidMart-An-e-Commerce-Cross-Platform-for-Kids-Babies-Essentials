CREATE TABLE `user_info` (
  `ID` int(11) NOT NULL,
  `name` varchar(80) NOT NULL,
  `email` varchar(50) NOT NULL,
  `gender` varchar(15) NOT NULL,
  `country` varchar(30) NOT NULL,
  `number` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `position` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `buyer_address` (
  `add_id` int(10) NOT NULL,
  `ID` int(11) NOT NULL,
  `add_name` varchar(70) NOT NULL,
  `add_num` varchar(30) NOT NULL,
  `region` varchar(50) NULL,
  `province` varchar(40) NULL,
  `city` varchar(40) NULL,
  `brgy` varchar(100) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `products` (
  `pid` int(10) NOT NULL,
  `seller_ID` int(10) NOT NULL,
  `pcategory` varchar(50) NOT NULL,
  `ptitle` varchar(50) NOT NULL,
  `pdesc` text NOT NULL,
  `pimage` mediumblob DEFAULT NULL,
  `trending` varchar(10) NOT NULL DEFAULT 'No',
  `num_sold` int(10) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `product_archive` (
  `pid` int(10) PRIMARY KEY NOT NULL,
  `seller_ID` int(10) NOT NULL,
  `pcategory` varchar(50) NOT NULL,
  `ptitle` varchar(50) NOT NULL,
  `pdesc` text NOT NULL,
  `pimage` mediumblob DEFAULT NULL,
  `trending` varchar(10) NOT NULL DEFAULT 'No',
  `num_sold` int(10) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `product_images` (
  `imgid` int(10) NOT NULL,
  `pid` int(10) NOT NULL,
  `image` mediumblob NOT NULL,
  FOREIGN KEY (`pid`) REFERENCES products(`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `product_variations` (
  `vid` int(10) NOT NULL,
  `pid` int(10) NOT NULL,
  `variation` varchar(30) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `pstocks` int(10) NOT NULL,
  FOREIGN KEY (`pid`) REFERENCES products(`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `product_reviews` (
  `prid` int(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
  `pid` int(10),
  `oid` int(10),
  `seller_ID` int(10),
  `feedback_rating` int(10) NOT NULL,
  `review_img` mediumblob NULL,
  `feedback_review` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `buyer_cart` (
  `cid` int(10) NOT NULL AUTO_INCREMENT, 
  `ID` int(10) NOT NULL,                 
  `pid` int(10) NOT NULL,                
  `quantity` int(10) NOT NULL,           
  `variation` varchar(40) NOT NULL,      
  `price` decimal(8,2) NOT NULL,
  `total_unit_price` decimal(8,2) DEFAULT NULL,
  `grand_total` decimal(8,2) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'Cart',
  PRIMARY KEY (`cid`),
  FOREIGN KEY (`pid`) REFERENCES `products`(`pid`),
  FOREIGN KEY (`ID`) REFERENCES `user_info`(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE orders (
  `order_id` int(10) NOT NULL AUTO_INCREMENT,
  `order_datetime` datetime DEFAULT NULL, 
  `order_ship_datetime` datetime DEFAULT NULL,
  `order_delivered_datetime` datetime DEFAULT NULL,
  `order_completed` datetime DEFAULT NULL,
  `buyer_id` int(10) NOT NULL,
  `seller_ID` int(10) NOT NULL,
  `cid` int(10) NOT NULL,
  `add_id` int(10) DEFAULT NULL,
  `payment_method` varchar(30) DEFAULT NULL,
  `shipping_method` varchar(30) DEFAULT NULL,
  `shipping_fee` decimal(8,2) NOT NULL,
  `voucher` decimal(8,2) DEFAULT 40.00,
  `order_total` decimal(8,2) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'To Approve',
  `parcel_loc` varchar(100) NOT NULL DEFAULT 'Order is placed',
  PRIMARY KEY (`order_id`),
  FOREIGN KEY (`cid`) REFERENCES buyer_cart(`cid`),
  FOREIGN KEY (`buyer_id`) REFERENCES user_info(`ID`),
  FOREIGN KEY (`seller_ID`) REFERENCES products(`seller_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `order_items` (
  `item_id` int(10) NOT NULL AUTO_INCREMENT,
  `order_id` int(10) NOT NULL,
  `pid` int(10) NOT NULL,
  `cid` int(10) NULL,
  `variation` varchar(40) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `quantity` int(10) NOT NULL,
  PRIMARY KEY (`item_id`),
  FOREIGN KEY (`order_id`) REFERENCES orders(`order_id`),
  FOREIGN KEY (`pid`) REFERENCES products(`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `notifications` (
  `nid` int(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
  `notif_datetime` datetime NULL,
  `order_id` int(10) NULL,
  `buyer_id` int(10) NULL,
  `seller_id` int(10) NULL,
  `position` varchar(30) NULL,
  `snotif_title` varchar(50) NULL,
  `snotif_text` text NULL,
  `bnotif_title` varchar(50) NULL,
  `bnotif_text` text NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `messages` (
  `msgid` int(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
  `buyer_id` int(10) NULL,
  `seller_id` int(10) NULL,
  `pid` int(10) NULL,
  `msg_img` mediumblob NULL,
  `position` varchar(30) NULL,
  `bmsg_text` text NULL,
  `smsg_text` text NULL,
  `msg_datetime` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;