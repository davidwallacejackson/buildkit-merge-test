# syntax=docker/dockerfile:1.4
FROM ubuntu
ENV SOMEENV=bar
ENTRYPOINT [ "ls", "/" ]
RUN echo bar >> /foo2
COPY --link foo.txt /
COPY --link bar.txt /
