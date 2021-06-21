FROM openjdk:8-jdk

ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_NDK /opt/android-ndk-linux
ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 6.8.3
ENV JAVA_OPTS "-Xmx4g -Xms4g -Dfile.encoding=UTF-8"

# Apt Hacks
RUN apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-key 7638D0442B90D010
RUN apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-key 8B48AD6246925553
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update
RUN echo 'Acquire::Check-Valid-Until "0";' > /etc/apt/apt.conf.d/10no--check-valid-until

# Android SDK
RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm android-sdk-tools.zip

# Android NDK
RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/android-ndk-r19b-linux-x86_64.zip -O android-ndk-tools.zip \
    && unzip -q android-ndk-tools.zip -d ${ANDROID_NDK} \
    && rm android-ndk-tools.zip

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_NDK}

# Install Android SDK
RUN yes | sdkmanager --licenses

RUN sdkmanager "tools" "platform-tools"
RUN yes | sdkmanager \
    "platforms;android-29" \
    "build-tools;29.0.3" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
    "add-ons;addon-google_apis-google-24"

# Gradle.
RUN set -o errexit -o nounset \
    && wget -O gradle.zip "https://artifactory.svc.bird.co/artifactory/gradle-distributions/gradle-${GRADLE_VERSION}-all.zip" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mkdir -p /opt \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

# Node >:(
RUN apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash \
    && apt-get install nodejs -yq

WORKDIR /src
