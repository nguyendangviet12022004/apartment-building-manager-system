-- Migration script to add new profile fields
-- Run this if Hibernate auto-update doesn't work

USE apartment_building_manager_system;

-- Add new columns to _user table
ALTER TABLE _user 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS date_of_birth VARCHAR(10),
ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500),
ADD COLUMN IF NOT EXISTS language VARCHAR(50),
ADD COLUMN IF NOT EXISTS email_notifications BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS push_notifications BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS theme VARCHAR(20) DEFAULT 'Light';

-- Add new column to residents table
ALTER TABLE residents 
ADD COLUMN IF NOT EXISTS emergency_contact_relationship VARCHAR(50);

-- Verify the changes
DESCRIBE _user;
DESCRIBE residents;

-- Optional: Set default values for existing users
UPDATE _user 
SET email_notifications = TRUE, 
    push_notifications = TRUE, 
    theme = 'Light',
    language = 'English'
WHERE email_notifications IS NULL;

SELECT 'Migration completed successfully!' as status;
