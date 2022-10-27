# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'my_observable'

class TestMyObservable < MiniTest::Test
  class TestObservable
    include MyObservable

    def notify(*args)
      changed
      notify_observers(*args)
    end
  end

  class TestWatcher
    def initialize(observable)
      @notifications = []
      observable.add_observer(self)
    end

    attr_reader :notifications

    def update(*args)
      @notifications << args
    end
  end

  def test_observers
    observable = TestObservable.new

    assert_equal(0, observable.count_observers)

    watcher1 = TestWatcher.new(observable)

    assert_equal(1, observable.count_observers)

    observable.notify("test", 123)

    watcher2 = TestWatcher.new(observable)

    assert_equal(2, observable.count_observers)

    observable.notify(42)

    assert_equal([["test", 123], [42]], watcher1.notifications)
    assert_equal([[42]], watcher2.notifications)

    observable.delete_observer(watcher1)

    assert_equal(1, observable.count_observers)

    observable.notify(:cats)

    assert_equal([["test", 123], [42]], watcher1.notifications)
    assert_equal([[42], [:cats]], watcher2.notifications)

    observable.delete_observers

    assert_equal(0, observable.count_observers)

    observable.notify("nope")

    assert_equal([["test", 123], [42]], watcher1.notifications)
    assert_equal([[42], [:cats]], watcher2.notifications)
  end

  # Down here is the code from https://docs.ruby-lang.org/ja/latest/class/Observable.html

  class Ticker          ### Periodically fetch a stock price.
    include MyObservable

    def run(i)
      price = Price.fetch(i)
      print "Current price: #{price}\n"
      changed                 # notify observers
      notify_observers(Time.now, price)
    end
  end

  class Price           ### A mock class to fetch a stock price (60 - 140).
    def self.fetch(i)
      case i
      when 0 then 60
      when 1 then 100
      when 2 then 140
      end
    end
  end

  class Warner          ### An abstract observer of Ticker objects.
    def initialize(ticker, limit)
      @limit = limit
      ticker.add_observer(self)
    end
  end

  class WarnLow < Warner
    def update(time, price)       # callback for observer
      if price < @limit
        print "Price below #@limit: #{price}\n"
      end
    end
  end

  class WarnHigh < Warner
    def update(time, price)       # callback for observer
      if price > @limit
        print "Price above #@limit: #{price}\n"
      end
    end
  end

  def test_ticker
    ticker = Ticker.new
    WarnLow.new(ticker, 80)
    WarnHigh.new(ticker, 120)
    assert_output "Current price: 60\nPrice below 80: 60\n" do
      ticker.run(0)
    end
    assert_output "Current price: 100\n" do
      ticker.run(1)
    end
    assert_output "Current price: 140\nPrice above 120: 140\n" do
      ticker.run(2)
    end
  end

  class EmailObserver
    def update(*)
      puts 'Email sent'
    end
  end

  class ChatObserver
    def update(*)
      puts 'Chat sent'
    end
  end

  def test_dual_observers
    observable = TestObservable.new
    observable.add_observer(EmailObserver.new)
    observable.add_observer(ChatObserver.new)
    assert_output "Email sent\nChat sent\n" do
      observable.notify
    end
  end

  class MyObserver
    def my_update(*)
      puts 'my_update called'
    end
  end

  class AnotherObserver
    def another_update(*)
      puts 'another_update called'
    end
  end

  def test_observable_different_func
    observable = TestObservable.new
    observable.add_observer(MyObserver.new, :my_update)
    observable.add_observer(AnotherObserver.new, :another_update)
    assert_output "my_update called\nanother_update called\n" do
      observable.notify
    end
  end
end
