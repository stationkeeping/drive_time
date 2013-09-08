require 'dotenv'
require 'drive_time'
require "log4r"

Dotenv.load
DriveTime::log_level = Log4r::DEBUG
