基本用法

```vue
<template>
  <vue-player-tool
   :entryData="data"
    />
</template>

<script>
export default {
  data() {
    return {
      data: {
          m3u8Url: "http://ph3h7suhv.bkt.clouddn.com/sleepPalnVideo.m3u8",
          back:"https://oimdztrab.qnssl.com/sleepplan/bg_video_cover@2x.png",
          title: "蜗牛睡眠研究院出品",
          description: "入睡困难、夜间易醒、作息不规律…加入改善计划， 帮你获得优质睡眠！"
       }
    }
  }
}
</script>
```