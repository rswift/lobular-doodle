#
# This file specifies all the required inputs for the module
# to work for consumers in a variety of context
#
# https://www.terraform.io/docs/language/values/variables.html
#

#
# This variable has a default value set, therefore when the module
# is called, this does not need to be set, but can be to override
# the default value
#
variable "retention_in_days" {
    default     = 14
    description = "The number of days to retain the logs"
}

#
# These variables do not have a default and therefore will force
# the configuration that uses the module to set a value, thereby
# allowing the module owner/author to enforce what data the consumer
# must provide...
#
variable "name" {
    description = "The name of the log group to create"
}

variable "billing_owner" {
    description = "Somewhat trite example of a tag"
}
