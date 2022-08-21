#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include <stdio.h>
#include "platform.h"

/************************** Constant Definitions *****************************/

#define LED_DIRECTION  0x00   /* Assumes bit 0 of GPIO is connected to an LED  */
#define KEY_DIRECTION  0x11
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define GPIO_EXAMPLE_DEVICE_ID  XPAR_GPIO_0_DEVICE_ID

/*
 * The following constant is used to wait after an LED is turned on to make
 * sure that it is visible to the human eye.  This constant might need to be
 * tuned for faster or slower processor speeds.
 */
#define LED_VALUE   0xF0

/*
 * The following constant is used to determine which channel of the GPIO is
 * used for the LED if there are 2 channels supported.
 */
#define LED_CHANNEL 1
#define KEY_CHANNEL 2

XGpio Gpio; /* The Instance of the GPIO Driver */






int main()
{
        int key_value;
		/* Initialize the GPIO driver */
		XGpio_Initialize(&Gpio, GPIO_EXAMPLE_DEVICE_ID);

		/* Set the direction for all signals as inputs except the LED output */
		XGpio_SetDataDirection(&Gpio, KEY_CHANNEL, KEY_DIRECTION);
		XGpio_SetDataDirection(&Gpio, LED_CHANNEL, LED_DIRECTION);

		key_value = XGpio_DiscreteRead(&Gpio, KEY_CHANNEL); //读取按键数据

	    /* Set the LED to High */
	    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, key_value);

    return 0;
}
