abstract class LimitedInterface {
  int get maximumUsage;
  int get usageLeft;

  set maximumUsage(int value);
  set usageLeft(int value);
}