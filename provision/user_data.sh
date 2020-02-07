set -e

# Download repo.
git clone https://github.com/bbstilson/bbstilson.github.io.git

# Go to provision directory.
cd bbstilson.github.io/provision

# Run the init script.
./init-letsencrypt.sh

# Start everything up.
docker-compose up
