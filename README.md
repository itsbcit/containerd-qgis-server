# docker-template
Template for new BCIT Docker image repositories





docker network create qgis
docker run -d --rm --name qgis-server --net=qgis --hostname=qgis-server \
              -v $(pwd)/data:/data:ro -p 5555:5555 \
              -e "QGIS_PROJECT_FILE=/data/world.qgs" \
              bcit.io/qgis-server

docker run --rm --name nginx --net=qgis --hostname=nginx \
              -v $(pwd)/data/nginx.conf:/etc/nginx/conf.d/default.conf:ro -p 8080:80 \
              bcit.io/nginx
