package io.lbg.kafka.opa;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.serialization.LongSerializer;
import org.apache.kafka.common.serialization.StringSerializer;

import java.util.Properties;

@Slf4j
public class KafkaOpaProducer {

  private final static String TOPIC = "X";
  private final static String BOOTSTRAP_SERVERS = "broker:9093";
  private boolean keepRunning = true;

  public static void main(String[] args) {
    new KafkaOpaProducer().run();
  }

  private void run() {
    Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
    props.put(ProducerConfig.CLIENT_ID_CONFIG, "KafkaExampleProducer");
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, LongSerializer.class.getName());
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

    props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");

    props.put(SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, "/etc/kafka/secrets/kafka.producer.truststore.jks");
    props.put(SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, "confluent");
    props.put(SslConfigs.SSL_KEYSTORE_LOCATION_CONFIG, "/etc/kafka/secrets/kafka.producer.keystore.jks");
    props.put(SslConfigs.SSL_KEYSTORE_PASSWORD_CONFIG, "confluent");
    props.put(SslConfigs.SSL_KEY_PASSWORD_CONFIG, "confluent");

    props.put(SaslConfigs.SASL_MECHANISM, "GSSAPI");
    props.put(SaslConfigs.SASL_KERBEROS_SERVICE_NAME, "kafka");

    while (keepRunning) {
      try {

        long index = 0;
        try (KafkaProducer<Long, String> producer = new KafkaProducer<>(props)) {
          while (keepRunning) {
            String value = "{\"id\":" + ++index + (index % 2 == 0 ? ",\"k\":\"v\"" : "") + "}";
            final ProducerRecord<Long, String> record = new ProducerRecord<>(TOPIC, index, value);
            log.debug("{}", record);
            producer.send(record).get();
            try {
              Thread.sleep(2000);
            } catch (InterruptedException ignored) {
            }
          }
        }
      } catch (Exception ignored) {
        try {
          Thread.sleep(2000);
        } catch (InterruptedException ignored2) {
        }
      }
    }
  }
}
