import Alpine from "alpinejs";
import CTFd from "./index";

window.Alpine = Alpine;

Alpine.data("HeroPanel", () => ({
  now: Math.floor(Date.now() / 1000),
  start: null,
  end: null,
  timer: "",
  label: "",
  days: "00",
  hours: "00",
  minutes: "00",
  seconds: "00",
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
      this.label = "STARTS IN";
      target = this.start - this.now;
    } else if (this.end && this.now < this.end) {
      this.label = "EVENT LIVE";
      target = this.end - this.now;
    } else if (this.start && this.now >= this.start && !this.end) {
      this.label = "Event Started At";
      let d = new Date(this.start * 1000);
      this.timer = d.toLocaleTimeString([], { hour12: false });
      this.days = this.hours = this.minutes = this.seconds = "00";
      return;
    } else {
      this.label = "EVENT ENDED";
      this.timer = "00:00:00";
      this.days = this.hours = this.minutes = this.seconds = "00";
      return;
    }

    if (target > 0) {
      let d = Math.floor(target / 3600 / 24);
      let h = Math.floor(target / 3600) % 24;
      let m = Math.floor((target % 3600) / 60);
      let s = target % 60;
      this.days = String(d).padStart(2, "0");
      this.hours = String(h).padStart(2, "0");
      this.minutes = String(m).padStart(2, "0");
      this.seconds = String(s).padStart(2, "0");
      this.timer = [d, h, m, s].map(v => (v < 10 ? "0" + v : v)).join(":");
    }
  },
}));

Alpine.start();
