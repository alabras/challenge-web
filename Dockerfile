FROM node:lts-alpine as Build
WORKDIR /app
COPY . ./
ENV NODE_ENV=production
ENV DISABLE_ESLINT_PLUGIN=true
ENV GENERATE_SOURCEMAP=false
RUN npm install ci --production
RUN npm run build


FROM nginx:stable
ENV NODE_ENV=production
WORKDIR /usr/myapp

#config environment at runtime
ENV ENV_FILE=/usr/www/env-config.js
COPY ./env.sh .
RUN chmod +x env.sh

WORKDIR /usr/www
COPY .env .

COPY nginx.conf /etc/nginx/conf.d/default.conf

## add permissions
RUN chown -R nginx:nginx /usr/www && chmod -R 755 /usr/www && \
  chown -R nginx:nginx /var/cache/nginx && \
  chown -R nginx:nginx /var/log/nginx && \
  chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
  chown -R nginx:nginx /var/run/nginx.pid

## switch to non-root user
USER nginx

COPY --from=build /app/build .
EXPOSE 8080
CMD ["/bin/bash", "-c", "/usr/myapp/env.sh && nginx -g \"daemon off;\""]
