-- ========================================================
-- 1. KHỞI TẠO DATABASE
-- ========================================================
DROP DATABASE IF EXISTS MoneyLoverDB;
CREATE DATABASE MoneyLoverDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE MoneyLoverDB;

-- ========================================================
-- 2. TẠO BẢNG USERS (NGƯỜI DÙNG)
-- ========================================================
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    role ENUM('USER', 'ADMIN') DEFAULT 'USER',
    is_verified BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    theme ENUM('LIGHT', 'DARK', 'SPECIAL') DEFAULT 'LIGHT',
    language VARCHAR(10) DEFAULT 'vi',
    travel_mode BOOLEAN DEFAULT FALSE,
    travel_currency CHAR(3) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ========================================================
-- 3. TẠO BẢNG WALLETS (VÍ)
-- ========================================================
CREATE TABLE Wallets (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    type ENUM('CASH', 'BANK', 'E_WALLET', 'CREDIT') NOT NULL,
    currency CHAR(3) DEFAULT 'VND',
    initial_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    is_excluded BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 4. TẠO BẢNG CATEGORIES (DANH MỤC)
-- ========================================================
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT DEFAULT NULL, 
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(255) NOT NULL,
    type ENUM('INCOME', 'EXPENSE') NOT NULL,
    parent_id INT DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES Categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ========================================================
-- 5. TẠO BẢNG DEBTS_LOANS (NỢ VÀ CHO VAY)
-- ========================================================
CREATE TABLE Debts_Loans (
    debt_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('PAYABLE', 'RECEIVABLE') NOT NULL,
    person_name VARCHAR(100) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    due_date DATE,
    note TEXT,
    is_finished BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 6. TẠO BẢNG SAVING_GOALS (MỤC TIÊU TIẾT KIỆM)
-- (Được đưa lên TRƯỚC Transactions để Transaction có thể tham chiếu tới)
-- ========================================================
CREATE TABLE Saving_Goals (
    goal_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    target_amount DECIMAL(15,2) NOT NULL,
    current_amount DECIMAL(15,2) DEFAULT 0,
    deadline DATE,
    status ENUM('IN_PROGRESS', 'COMPLETED', 'FAILED') DEFAULT 'IN_PROGRESS',
    color VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 7. TẠO BẢNG TRANSACTIONS (GIAO DỊCH)
-- (Cập nhật: Thêm saving_goal_id)
-- ========================================================
CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    wallet_id INT NOT NULL, -- Ví nguồn tiền đi ra
    
    -- Các cột đích đến của dòng tiền
    to_wallet_id INT DEFAULT NULL, -- Nếu chuyển sang ví khác
    saving_goal_id INT DEFAULT NULL, -- [MỚI] Nếu nạp vào mục tiêu tiết kiệm
    debt_id INT DEFAULT NULL, -- Nếu trả nợ hoặc đi vay
    
    category_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_date DATETIME NOT NULL,
    note TEXT,
    image_url VARCHAR(500),
    exclude_report BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES Wallets(wallet_id) ON DELETE CASCADE,
    FOREIGN KEY (to_wallet_id) REFERENCES Wallets(wallet_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY (debt_id) REFERENCES Debts_Loans(debt_id) ON DELETE SET NULL,
    FOREIGN KEY (saving_goal_id) REFERENCES Saving_Goals(goal_id) ON DELETE SET NULL -- [MỚI] Liên kết tới mục tiêu
) ENGINE=InnoDB;

-- ========================================================
-- 8. TẠO BẢNG BUDGETS (NGÂN SÁCH)
-- ========================================================
CREATE TABLE Budgets (
    budget_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    wallet_id INT DEFAULT NULL,
    amount_limit DECIMAL(15,2) NOT NULL,
    period ENUM('WEEKLY', 'MONTHLY', 'CUSTOM') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    alert_threshold INT DEFAULT 80,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES Wallets(wallet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 9. TẠO BẢNG GROUPS_ (QUỸ NHÓM)
-- ========================================================
CREATE TABLE Groups_ (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 10. TẠO BẢNG GROUP_MEMBERS (THÀNH VIÊN NHÓM)
-- ========================================================
CREATE TABLE Group_Members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('LEADER', 'MEMBER') DEFAULT 'MEMBER',
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED') DEFAULT 'PENDING',
    joined_at DATETIME,
    balance DECIMAL(15,2) DEFAULT 0,
    FOREIGN KEY (group_id) REFERENCES Groups_(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_member (group_id, user_id)
) ENGINE=InnoDB;

-- ========================================================
-- 11. TẠO BẢNG GROUP_TRANSACTIONS (GIAO DỊCH QUỸ)
-- ========================================================
CREATE TABLE Group_Transactions (
    group_trans_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    payer_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    type ENUM('EXPENSE', 'CONTRIBUTION') NOT NULL,
    description VARCHAR(255) NOT NULL,
    trans_date DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES Groups_(group_id) ON DELETE CASCADE,
    FOREIGN KEY (payer_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 12. TẠO BẢNG NOTICES (THÔNG BÁO)
-- ========================================================
CREATE TABLE Notices (
    notice_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type ENUM('SYSTEM', 'BUDGET', 'DEBT', 'GROUP', 'AI') NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- 13. TẠO BẢNG USER_ACHIEVEMENTS (DANH HIỆU)
-- ========================================================
CREATE TABLE User_Achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    achievement_code VARCHAR(50) NOT NULL,
    unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_viewed BOOLEAN DEFAULT FALSE,
    progress INT DEFAULT 100,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- DROP DATABASE IF EXISTS MoneyLoverDB;  -- comment: safe drop option

