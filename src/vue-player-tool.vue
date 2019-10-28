<template>
  <div class="vue-player-tool">
    <video ref="video" class="video__box" controls></video>
    <div class="video__con" v-if="false">
      <div
        class="video__con--btn stop"
        v-if="playState.isPlaying"
        @click="togglePlay"
      ></div>
      <div class="video__con--btn play" v-else @click="togglePlay"></div>
      <div class="video__con--time now">{{ playState.ctime }}</div>
      <div class="video__con--progress">
        <input
          type="range"
          name="range"
          id="range"
          v-model="playState.volume"
          @input="changeVolume($event)"
          :style="{'background-size': playState.volume + '% 100%'}"
        />
      </div>
      <div class="video__con--time length">{{ playState.dtime }}</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VuePlayerTool',
  props: {
    entryData: {
      type: Object
    }
  },
  data() {
    return {
      timer: 0, //用户定时
      timeout: null, //定时器
      timerCurr: '', //定时器剩余时长
      timerLength: 0, //定时器剩余时长
      like: false, //是否收藏
      loop: false, //是否循环
      playerOptions: {
        //播放器配置
        type: 'application/x-mpegURL',
        // src: 'http://obbfzjhuq.bkt.clouddn.com/WEw3RTROUVFFT0MxNTY4MTAzODQ5NTQ1',
        src: '',
        preload: true,
        autoplay: true,
        isLoop: false,
        poster: './src/images/video.png',
        playsinline: true,
        title: '舒缓呼吸练习'
      },
      playState: {
        duration: 0,
        loadedTime: 0,
        currentTime: 0,
        isPlaying: false,
        ctime: '00:00', // 当前播放时长
        dtime: '00:00', //音频长度
        volume: 0
      },
      vipShow: false,
      isComplete: false,
      closeScreen: false, //是否息屏
      screenTimer: null //息屏定时器
    }
  },
  computed: {
    video() {
      return this.$refs.video
    }
  },
  created() {},
  mounted() {
    // this.initAudio()
  },
  watch: {
    entryData: {
      //深度监听，可监听到对象、数组的变化
      immediate: true,
      handler(newV, oldV) {
        this.playerOptions.src = this.entryData.m3u8Url
        this.playerOptions.poster = this.entryData.back
        this.playerOptions.title = this.entryData.title
        this.playerOptions.description = this.entryData.description
        this.$nextTick(() => {
          this.initAudio()
        })
      },
      deep: true
    }
  },
  methods: {
    initAudio() {
      console.log(this.video)
      this.video.preload = this.playerOptions.preload || true
      this.video.autoplay = this.playerOptions.autoplay || false
      this.video.poster = this.playerOptions.poster || ''
      if (this.playerOptions.playsinline) {
        this.video.setAttribute('playsinline', this.playerOptions.playsinline)
        this.video.setAttribute(
          'webkit-playsinline',
          this.playerOptions.playsinline
        )
        this.video.setAttribute(
          'x5-playsinline',
          this.playerOptions.playsinline
        )
        this.video.setAttribute('x5-video-player-type', 'h5')
        this.video.setAttribute('x5-video-player-fullscreen', false)
      }
      if (
        this.playerOptions.type === 'application/x-mpegURL' ||
        this.playerOptions.type === 'application/vnd.apple.mpegURL'
      ) {
        try {
          const Hls = require('hls.js')
          if (Hls.isSupported()) {
            if (!this.hls) {
              this.hls = new Hls()
            }
            this.hls.loadSource(this.playerOptions.src)
            this.hls.attachMedia(this.video)
            if (this.playerOptions.autoplay) {
              let _this = this
              this.hls.on(Hls.Events.MANIFEST_PARSED, function() {
                _this.audio.play()
              })
            }
          } else {
            console.warn('HLS is not supported on your browser')
            this.video.src = this.playerOptions.src
            if (this.playerOptions.autoplay) {
              let _this = this
              this.video.addEventListener('loadedmetadata', function() {
                _this.audio.play()
              })
            }
          }
        } catch (e) {
          console.log(e)
          console.warn('hls.js is required to support m3u8')
          this.video.src = this.playerOptions.src
        }
      } else {
        this.video.src = this.playerOptions.src
      }
      this.video.addEventListener('play', this.onAudioPlay)
      this.video.addEventListener('pause', this.onAudioPause)
      this.video.addEventListener('abort', this.onAudioPause)
      this.video.addEventListener('progress', this.onAudioProgress)
      this.video.addEventListener('durationchange', this.onAudioDurationChange)
      this.video.addEventListener('seeking', this.onAudioSeeking)
      this.video.addEventListener('seeked', this.onAudioSeeking)
      this.video.addEventListener('timeupdate', this.onAudioSeeking)
      this.video.addEventListener('volumechange', this.onAudioVolumeChange)
      this.video.addEventListener('ended', this.onAudioEnded)
    },
    onAudioPlay() {
      this.playState.isPlaying = true
    },
    onAudioPause() {
      this.playState.isPlaying = false
    },
    onAudioVolumeChange() {
      console.log(this.video.volume, this.video.muted)
    },
    onAudioProgress() {
      if (this.video.buffered.length) {
        this.playState.loadedTime = this.video.buffered.end(
          this.video.buffered.length - 1
        )
      } else {
        this.playState.loadedTime = 0
      }
    },
    onAudioDurationChange() {
      if (this.video.duration !== 1) {
        this.playState.duration = this.video.duration
        this.playState.dtime = this.base_turnTime(parseInt(this.video.duration))
      }
    },
    onAudioSeeking() {
      this.playState.currentTime = this.video.currentTime
      if (this.playState.currentTime > 0 && this.playState.duration > 0) {
        this.playState.volume = parseInt(
          (this.playState.currentTime * 100) / this.playState.duration
        )
      } else {
        this.playState.volume = 0
      }
      this.playState.ctime = this.base_turnTime(
        parseInt(this.video.currentTime)
      )
    },
    onAudioEnded() {
      if (this.playerOptions.isLoop) {
        this.video.play()
      }
      if (
        !this.isComplete &&
        !this.entryData.back &&
        this.entryData.ended != 'true'
      ) {
        this.finishedTask()
      }
    },
    togglePlay() {
      if (this.playState.isPlaying) {
        this.video.pause()
      } else {
        this.video.play()
      }
    },
    fullscreen() {
      this.video.requestFullscreen()
      this.video.webkitRequestFullScreen()
    },
    base_turnTime(time) {
      var finallTime
      var num = Math.floor(time / 60)
      if (num < 1) {
        time < 10 ? (time = '0' + time) : (time = time)
        finallTime = '0' + num + ':' + time
      } else {
        time = time - num * 60
        time < 10 ? (time = '0' + time) : (time = time)
        num < 10 ? (num = '0' + num) : (num = num)
        finallTime = num + ':' + time
      }
      return finallTime
    }
  }
}
</script>

<style lang="scss" scoped>
.vue-player-tool {
  width: 100%;
  height: 500px;
  position: relative;
}

video {
  width: 100%;
  height: 500px;
}

.video {
  width: 100%;
  height: 100%;
  background: #000;

  &__bg::after {
    display: block;
    content: '';
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
    // background:#000;
  }

  &__title {
    width: 400px;
    text-align: center;
    font-size: 36px;
    color: #fff;
    position: absolute;
    top: 50%;
    left: 50%;
    margin-left: -200px;
    margin-top: -172px;
    font-weight: 600;
    line-height: 50px;
  }

  &__desc {
    width: 400px;
    text-align: center;
    font-size: 28px;
    color: #fff;
    position: absolute;
    top: 304px;
    left: 50%;
    margin-left: -200px;
    line-height: 40px;
  }

  &__back {
    width: 48px;
    height: 48px;
    background: rgba(216, 216, 216, 0.2);
    border-radius: 12px;
    position: absolute;
    top: 20px;
    left: 32px;
  }

  &__back::before {
    display: block;
    content: '';
    width: 13px;
    height: 13px;
    border: 4px solid #fff;
    border-width: 0 0 3px 3px;
    transform: rotate(45deg);
    position: absolute;
    top: 16px;
    left: 18px;
  }

  &__fullscreen {
    width: 40px;
    height: 40px;
    background-color: rgba(216, 216, 216, 0.2);
    background-image: url('./images/btn_fullscreen.png');
    background-repeat: no-repeat;
    background-size: 40px;
    border-radius: 12px;
    position: absolute;
    top: 50%;
    right: 32px;
    margin-top: -172px;
  }

  &__con {
    position: absolute;
    top: 50%;
    margin-top: 138px;
    width: 100%;
    height: 52px;
    display: flex;
    align-items: center;
    justify-content: space-between;

    &--btn {
      width: 80px;
      height: 80px;
      background: url('./images/btn_video_pause.png') no-repeat center;
      background-size: 36px;
    }

    &--btn.stop {
      background: url('./images/btn_video_play.png') no-repeat center;
      background-size: 36px;
    }

    &--progress {
      flex: 1;
      background: transparent;
      margin: 0 32px;

      input {
        -webkit-appearance: none;
        width: 100%;
        background:
          url('./images/ic_music_timeline.png') no-repeat,
          rgba(255, 255, 255, 0.3);
        height: 6px;
        border-radius: 4px;
      }

      input[type='range']::-webkit-slider-thumb {
        -webkit-appearance: none;
        height: 41px;
        width: 41px;
        background: url('./images/ic_player_curr.png') no-repeat center;
        background-size: 100%;
        border: 0;
        border-radius: 50%;
      }
    }

    &--time {
      width: 96px;
      height: 34px;
      line-height: 34px;
      margin: 0 auto;
      color: #fdfdfd;
      display: flex;
      justify-content: space-between;
      align-items: center;

      div {
        font-size: 24px;
        line-height: 34px;
      }
    }

    &--time.now {
      text-align: right;
    }
  }

  &__box {
    position: absolute;
    top: 50%;
    margin-top: -210px;
    width: 100%;
    height: 420px;
  }
}
</style>
