module TimeReadable
  def time_readable(total_seconds)
    return nil unless total_seconds

    int_seconds = total_seconds.to_i
    left_over = (total_seconds - int_seconds).round(3)
    seconds = int_seconds % 60
    seconds += left_over if left_over > 0.0
    minutes = (int_seconds / 60) % 60
    hours = (int_seconds / (60 * 60)) % 24
    days = int_seconds / (60 * 60 * 24)

    out = ''
    out += "#{days}d " if days > 0
    out += "#{hours}h " if days > 0 || hours > 0
    out += "#{minutes}m #{seconds}s"
    out
  end
end
