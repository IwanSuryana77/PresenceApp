public class MyApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        Map<String, Object> config = new HashMap<>();
        config.put("dv8zwl76d", "facesign_unsigned");

        MediaManager.init(this, config);
    }
}