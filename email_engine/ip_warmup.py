# IP Warmup (gradual volume, Gmail/Microsoft reputation)
class IPWarmup:
    def __init__(self, total_volume, days=7):
        self.total_volume = total_volume
        self.days = days
        self.schedule = self.generate_schedule()

    def generate_schedule(self):
        return [int(self.total_volume * (i+1)/self.days) for i in range(self.days)]

    def get_today_volume(self, day):
        if 1 <= day <= self.days:
            return self.schedule[day-1]
        return 0
