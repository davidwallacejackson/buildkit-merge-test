# buildkit-merge-test

Trying to reproduce the new behavior described in [this article about MergeOp and `COPY --link`](https://www.docker.com/blog/image-rebase-and-improved-remote-cache-support-in-new-buildkit/).

This script builds 3 images with buildkit, each of which perform two `COPY --link` operations. The Dockerfile is

```Dockerfile
# syntax=docker/dockerfile:1.4
FROM ubuntu
COPY --link foo.txt /
COPY --link bar.txt /
```

When building the first image, `foo.txt` contains `foo` and `bar.txt` contains `bar`. As expected, both `COPY` operations are performed:

```
[+] Building 5.2s (18/18) FINISHED                                                                       

........

=> [2/3] COPY --link foo.txt /                                                                                  0.0s
=> [3/3] COPY --link bar.txt /                                                                                  0.0s
........

=> => pushing manifest for docker.io/davidwallacejackson/buildkit-merge-test:652A5E7E-A99D-4A18-BCA4-53731C48D  0.3s
=> [auth] davidwallacejackson/buildkit-merge-test:pull,push token for registry-1.docker.io                      0.0s
```

Using the `foo.txt: foo`/`bar.txt: bar` image as cache, we build an image for `foo.txt: foo`/`bar.txt: baz`. Only the second `COPY` is performed, since `foo.txt` has not changed, as we'd expect with a typical `COPY`:

```
[+] Building 2.3s (15/15) FINISHED                                                                       ........
 => CACHED [2/3] COPY --link foo.txt /                                                                           0.0s
 => [3/3] COPY --link bar.txt /                                                                                  0.0s
```

Using the `foo.txt: foo`/`bar.txt: bar` image as cache, we build an image for `foo.txt: baz`/`bar.txt: baz`. **Both** `COPY` operations are performed:

```
[+] Building 1.2s (14/14) FINISHED                                                                    ........
 => [2/3] COPY --link foo.txt /                                                                                  0.0s
 => [3/3] COPY --link bar.txt /      
```

This behavior is what I'd expect from a typical docker `COPY` -- but [this example from the above article](https://www.docker.com/blog/image-rebase-and-improved-remote-cache-support-in-new-buildkit/#example-better-remote-cache-support) suggests that with `COPY --link`, I should instead see that the third layer is cached, even though the second layer has changed.

The article doesn't show the terminal output, so it could be that I've misunderstood the new functionality: maybe the cached layers still have to be created locally, but don't get pushed? If so, it's also not clear that this is happening -- I've tried versions of this experiment where I push all the images, and I've noticed that there's still a `=> => pushing layers` step listed even if I rebuild an image where all layers are in the remote cache (though it is, of course, a pretty quick one).

Running the test
----------------

The version of Docker I used to run this test was:
```
davidjackson@MacBook-Pro buildkit-test % docker version
Client:
 Cloud integration: v1.0.22
 Version:           20.10.13
 API version:       1.41
 Go version:        go1.16.15
 Git commit:        a224086
 Built:             Thu Mar 10 14:08:43 2022
 OS/Arch:           darwin/arm64
 Context:           default
 Experimental:      true

Server: Docker Desktop 4.6.1 (76265)
 Engine:
  Version:          20.10.13
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.16.15
  Git commit:       906f57f
  Built:            Thu Mar 10 14:05:37 2022
  OS/Arch:          linux/arm64
  Experimental:     false
 containerd:
  Version:          1.5.10
  GitCommit:        2a1d4dbdb2a1030dc5b01e96fb110a9d9f150ecc
 runc:
  Version:          1.0.3
  GitCommit:        v1.0.3-0-gf46b6ba
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
davidjackson@MacBook-Pro buildkit-test % docker buildx version
github.com/docker/buildx v0.8.1 5fac64c2c49dae1320f2b51f1a899ca451935554
```

You can run it yourself with `./test.sh`, but **BE AWARE THAT IT WILL CLEAR YOUR ENTIRE BUILDX CACHE**.
