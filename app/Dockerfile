FROM node:lts-alpine

ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /usr/src/app
COPY "package*.json" "./"
RUN npm install --production --silent && mv node_modules ../
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]