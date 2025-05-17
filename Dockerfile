FROM oven/bun:1.2.13-alpine AS build

WORKDIR /app

COPY package.json bun.lockb ./

COPY . .

RUN bun install --frozen-lockfile --production && bun build

# EXPOSE 3000

# CMD ["bun", "run", "start"]

# Production step with Nginx
FROM nginx:1.27.5-alpine3.21 AS production

WORKDIR /usr/share/nginx/html

COPY --from=build /app/dist ./

COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
