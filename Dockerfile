FROM docker.io/cm2network/steamcmd:steam-bookworm

USER root

RUN apt-get update && apt-get install -y wget
RUN dpkg --add-architecture i386 \
	&& wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
	&& wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

RUN apt-get update && apt-get install -y --install-recommends winehq-stable
RUN wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
	&& chmod +x /usr/bin/winetricks

RUN apt-get update && apt-get install -y xvfb zenity cabextract gosu

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

ENV STEAMAPPID 403240
ENV STEAMAPP squad
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV WORKSHOPID 393380
ENV MODPATH "${STEAMAPPDIR}/SquadGame/Plugins/Mods"
ENV MODS "()"
COPY ./entry.sh ${HOMEDIR}

RUN set -x \
	&& mkdir -p "${STEAMAPPDIR}" \
	&& chmod 755 "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
	&& chown "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}"

ENV PORT=7787 \
	QUERYPORT=27165 \
	RCONPORT=21114 \
	FIXEDMAXPLAYERS=80 \
	FIXEDMAXTICKRATE=50 \
	RANDOM=NONE

USER ${USER}
WORKDIR ${HOMEDIR}

ENTRYPOINT ["bash", "entry.sh"]

