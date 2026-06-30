import Alpine from "alpinejs";
import CTFd from "./index";

window.Alpine = Alpine;

Alpine.data("HeroPanel", () => ({
  now: Math.floor(Date.now() / 1000),
  start: null,
  end: null,
  timer: "",
  label: "",
  challengeCount: 0,

  async init() {
    this.start = parseInt(this.$el.dataset.start) || 0;
    this.end = parseInt(this.$el.dataset.end) || 0;
    this.challengeCount = parseInt(this.$el.dataset.challengeCount) || 0;

    this.updateTimer();
    setInterval(() => {
      this.updateTimer();
    }, 1000);

    // Optional: Update challenge count via API if needed
    // const challenges = await CTFd.pages.challenges.getChallenges();
    // this.challengeCount = challenges.length;
  },

  updateTimer() {
    this.now = Math.floor(Date.now() / 1000);
    let target = 0;

    if (this.start && this.now < this.start) {
      this.label = "Event Starts In";
      target = this.start - this.now;
    } else if (this.end && this.now < this.end) {
      this.label = "Time Remaining";
      target = this.end - this.now;
    } else if (this.start && this.now >= this.start && !this.end) {
      this.label = "Event Started At";
      let d = new Date(this.start * 1000);
      this.timer = d.toLocaleTimeString([], { hour12: false });
      return;
    } else {
      this.label = "Event Ended";
      this.timer = "00:00:00";
      return;
    }

    if (target > 0) {
      let d = Math.floor(target / 3600 / 24);
      let h = Math.floor(target / 3600) % 24;
      let m = Math.floor((target % 3600) / 60);
      let s = target % 60;
      this.timer = [d, h, m, s].map(v => (v < 10 ? "0" + v : v)).join(":");
    }
  },
}));

Alpine.start();
