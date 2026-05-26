FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

# 마이그레이션 실행 후 서버 시작
CMD ["sh", "-c", "node migrate.js && node app.js"]
