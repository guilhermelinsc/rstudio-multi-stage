# Summary:
    # This Dockerfile uses the RStudio Rocker image as base.
    # Using a multi-stage deployment, with Ubuntu LTS 24.04 as RUNTIME, the final image is trimmed by around 50%.
    # The final image have the default RStudio image packages plus "tidyverse" & "readxl".
    # The RStudio user can install additional packages, but they are lost when the container is destroyed.

# Stage 1: Build RStudio Server on Rocker RStudio image
FROM rocker/rstudio:latest AS builder

# Expose port for RStudio
EXPOSE 8787

# Optional: Add custom R packages or other dependencies if needed.
# Optional: Add required R packages to make then available at container start and persist after container destruction.
RUN R -e "install.packages(c('tidyverse', 'readxl'))"

# Stage 2: Build minimal multi-stage image based on Ubuntu
FROM ubuntu:24.04


# Copy necessary RStudio files from the builder image
COPY --from=builder /usr/lib/rstudio-server /usr/lib/rstudio-server
COPY --from=builder /usr/local/bin/rstudio-server /usr/bin/rstudio-server
COPY --from=builder /etc/rstudio /etc/rstudio
COPY --from=builder /usr/local/lib/R /usr/local/lib/R
COPY --from=builder /usr/local/bin/R /usr/local/bin/R

# Install R, runtime dependencies, create, and set rstudio user password 
# Default user/password is rstudio/rstudio. ### Do not recommended for public accessible deployments. ###
RUN apt update && \
    apt install -y --no-install-recommends \
        r-base \
        libsqlite3-0 \
        libblas3 \
        libdeflate0 \
        libicu74 \
        libgomp1 \
        libreadline8 \
        sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && useradd -m rstudio \
    && echo "rstudio:rstudio" | chpasswd \
    && usermod -aG sudo rstudio


# Expose RStudio's port
EXPOSE 8787

# Set entrypoint to start RStudio server
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--server-user=rstudio"]