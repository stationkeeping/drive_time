require 'dotenv'
require 'drive_time'
require "drive_time/initialisers/google_drive_initialiser"
require "log4r"

Dotenv.load
DriveTime::log_level = Log4r::DEBUG
