class MotivationalQuotes {
  static final List<String> quotes = [
    "The secret of getting ahead is getting started.",
    "You don't have to be great to start, but you have to start to be great.",
    "Small steps every day lead to big changes over time.",
    "Success is the sum of small efforts repeated day in and day out.",
    "The only way to do great work is to love what you do.",
    "Progress, not perfection, is what matters.",
    "Every accomplishment starts with the decision to try.",
    "You are capable of amazing things.",
    "Consistency is the key to success.",
    "Your future is created by what you do today, not tomorrow.",
    "The best time to plant a tree was 20 years ago. The second best time is now.",
    "Don't watch the clock; do what it does. Keep going.",
    "Believe you can and you're halfway there.",
    "It does not matter how slowly you go as long as you do not stop.",
    "The journey of a thousand miles begins with one step.",
    "You miss 100% of the shots you don't take.",
    "Hard work beats talent when talent doesn't work hard.",
    "The only person you should try to be better than is the person you were yesterday.",
    "Dreams don't work unless you do.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "The way to get started is to quit talking and begin doing.",
    "Do something today that your future self will thank you for.",
    "Every day is a fresh start.",
    "You are stronger than you think.",
    "The difference between ordinary and extraordinary is that little extra.",
    "Your limitation—it's only your imagination.",
    "Push yourself, because no one else is going to do it for you.",
    "Great things never come from comfort zones.",
    "Dream it. Wish it. Do it.",
    "Success doesn't just find you. You have to go out and get it.",
  ];

  static String getRandomQuote() {
    final random = DateTime.now().millisecondsSinceEpoch % quotes.length;
    return quotes[random];
  }

  static String getQuoteForDay(DateTime date) {
    // Use the day of year to get a consistent quote for the day
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }
}

