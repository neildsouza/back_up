defmodule BackUp.Util do
  def convert(secs) when 0 <= secs and secs < 60 do
    "0 hr(s) 0 mins #{secs} secs"
  end

  def convert(secs) when secs == 60 do
    "0 hr(s) 1 min 0 secs"
  end

  def convert(secs) when 60 < secs and secs < 3600 do
    mins = div(secs, 60)
    s = rem(secs, 60)
    "0 hr(s) #{mins} min(s) #{s} sec(s)"
  end

  def convert(secs) when secs == 3600 do
    "1 hr(s) 0 mins 0 secs"
  end

  def convert(secs) when secs > 3600 do
    h = div(secs, 3600)
    r = convert(rem(secs, 3600))
    "#{h} hr(s) " <> String.replace(r, "0 hr(s)", "")
  end
end
