# cn-math-taxonomy：纯静态站点（无构建步骤），用 nginx 直接托管。
# 构建：docker build -t cn-math-taxonomy .
# 运行：docker run -d -p 8080:80 --name cn-math-taxonomy cn-math-taxonomy
#       然后打开 http://localhost:8080/
# 数据（data/*.json）在构建时打进镜像；改了数据要先跑 scripts/validate.py，再重新构建。
FROM nginx:1.28-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html
RUN rm -f index.html 50x.html

# 与 scripts/deploy-cf.sh 发布的文件相同（.dockerignore 已排除 diagnose/README.md）
COPY index.html sw.js manifest.webmanifest .nojekyll ./
COPY assets/   ./assets/
COPY explore/  ./explore/
COPY diagnose/ ./diagnose/
COPY children/ ./children/
COPY data/     ./data/

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1
