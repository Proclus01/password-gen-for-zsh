# BRIEF INSTRUCTIONS ON USE:

# makepw Function Usage:
# 
# Generates random passwords with a mix of uppercase letters, lowercase letters, numbers, and special characters.
#
# - To generate a default password of length 20: 
#   $ makepw
#
# - To generate a password of a specific length, e.g., 25: 
#   $ makepw 25
#
# - To generate multiple passwords of default length 20, e.g., 5 passwords: 
#   $ makepw -n 5
#
# - To generate multiple passwords of a specific length, e.g., 5 passwords of length 25: 
#   $ makepw -n 5 25
#

### 

# WHAT THIS FUNCTION DOES:

# It has a pool of 94 possible characters.
# Some characters are not universally password-safe. 
# This is intentional, plenty of other configurations you can generate are safe.

# Ensuring Diversity: It first ensures the inclusion of at least one character 
# from each category (uppercase, lowercase, number, and special character) to enhance password strength. 
# This is done by generating one character from each category separately.

# Generating the Rest: After securing the diversity of the password, 
# it fills the remaining length with a random sequence of characters drawn from the entire set of 94 characters. 
# This ensures that the bulk of the password is unpredictable.

# Shuffling: Once the password is assembled with the guaranteed diverse parts followed by the randomly selected characters, the entire sequence is shuffled. 
# This shuffling is not done in chunks but rather by treating each character as a separate entity, 
# ensuring that the initial enforced diversity does not lead to a predictable pattern.

# Output: The function then outputs the shuffled password, ensuring that it is both complex and unique.

###

makepw() {
    local count=1
    local length=20

    # Check for the -n flag for multiple passwords
    if [[ "$1" == "-n" && "$2" =~ ^[0-9]+$ ]]; then
        count=$2
        shift 2
    fi

    # Check for password length argument
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        length=$1
    fi

    # Split character sets
    local alpha_upper="A-Z"
    local alpha_lower="a-z"
    local numbers="0-9"
    local special_chars='!@#$%^&*()-_=+[]{};:'\''",<.>/?\\|`~'

    for i in $(seq 1 $count); do
        # Parts to ensure diversity
        local upper_part=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "${alpha_upper}" | head -c 1)
        local lower_part=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "${alpha_lower}" | head -c 1)
        local number_part=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "${numbers}" | head -c 1)
        local special_part=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "${special_chars}" | head -c 1)

        # Rest of the password
        local chars="${alpha_upper}${alpha_lower}${numbers}${special_chars}"
        local rest_length=$((length-4))
        local rest_part=$(head -c 32768 /dev/urandom | LC_ALL=C tr -dc "${chars}" | head -c "$rest_length")

        local password="${upper_part}${lower_part}${number_part}${special_part}${rest_part}"

        # Shuffle the password using awk
        local shuffled_password=$(echo "$password" | fold -w1 | awk 'BEGIN {srand()} {print rand() "\t" $0}' | sort -n | cut -f2- | tr -d '\n')

        echo $shuffled_password
    done
}
