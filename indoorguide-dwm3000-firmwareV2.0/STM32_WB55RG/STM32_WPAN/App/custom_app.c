/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    App/custom_app.c
  * @author  MCD Application Team
  * @brief   Custom Example Application (Server)
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "app_common.h"
#include "dbg_trace.h"
#include "ble.h"
#include "custom_app.h"
#include "custom_stm.h"
#include "stm32_seq.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "../../Core/Src/Applications/Tag_app/tag_app.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  /* My_P2P_Server */
  uint8_t               Loc_xy_Notification_Status;
  /* USER CODE BEGIN CUSTOM_APP_Context_t */

  /* USER CODE END CUSTOM_APP_Context_t */

  uint16_t              ConnectionHandle;
} Custom_App_Context_t;

/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private defines ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macros -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
#define ON 1
#define OFF 0
/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/**
 * START of Section BLE_APP_CONTEXT
 */

static Custom_App_Context_t Custom_App_Context;

/**
 * END of Section BLE_APP_CONTEXT
 */

uint8_t UpdateCharData[247];
uint8_t NotifyCharData[247];

/* USER CODE BEGIN PV */
uint8_t tag_app_timer_id;

extern double current_location[2];
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
/* My_P2P_Server */
static void Custom_Loc_xy_Update_Char(void);
static void Custom_Loc_xy_Send_Notification(void);

/* USER CODE BEGIN PFP */
void send_tag_app_data_callback(void);

void send_tag_app_data(void);

/* USER CODE END PFP */

/* Functions Definition ------------------------------------------------------*/
void Custom_STM_App_Notification(Custom_STM_App_Notification_evt_t *pNotification)
{
  /* USER CODE BEGIN CUSTOM_STM_App_Notification_1 */

  /* USER CODE END CUSTOM_STM_App_Notification_1 */
  switch (pNotification->Custom_Evt_Opcode)
  {
    /* USER CODE BEGIN CUSTOM_STM_App_Notification_Custom_Evt_Opcode */

    /* USER CODE END CUSTOM_STM_App_Notification_Custom_Evt_Opcode */

    /* My_P2P_Server */
    case CUSTOM_STM_LOC_XY_NOTIFY_ENABLED_EVT:
      /* USER CODE BEGIN CUSTOM_STM_LOC_XY_NOTIFY_ENABLED_EVT */
    	Custom_App_Context.Loc_xy_Notification_Status = 1;
      /* USER CODE END CUSTOM_STM_LOC_XY_NOTIFY_ENABLED_EVT */
      break;

    case CUSTOM_STM_LOC_XY_NOTIFY_DISABLED_EVT:
      /* USER CODE BEGIN CUSTOM_STM_LOC_XY_NOTIFY_DISABLED_EVT */
    	Custom_App_Context.Loc_xy_Notification_Status = 0;
      /* USER CODE END CUSTOM_STM_LOC_XY_NOTIFY_DISABLED_EVT */
      break;

    case CUSTOM_STM_NOTIFICATION_COMPLETE_EVT:
      /* USER CODE BEGIN CUSTOM_STM_NOTIFICATION_COMPLETE_EVT */

      /* USER CODE END CUSTOM_STM_NOTIFICATION_COMPLETE_EVT */
      break;

    default:
      /* USER CODE BEGIN CUSTOM_STM_App_Notification_default */

      /* USER CODE END CUSTOM_STM_App_Notification_default */
      break;
  }
  /* USER CODE BEGIN CUSTOM_STM_App_Notification_2 */

  /* USER CODE END CUSTOM_STM_App_Notification_2 */
  return;
}

void Custom_APP_Notification(Custom_App_ConnHandle_Not_evt_t *pNotification)
{
  /* USER CODE BEGIN CUSTOM_APP_Notification_1 */

  /* USER CODE END CUSTOM_APP_Notification_1 */

  switch (pNotification->Custom_Evt_Opcode)
  {
    /* USER CODE BEGIN CUSTOM_APP_Notification_Custom_Evt_Opcode */

    /* USER CODE END P2PS_CUSTOM_Notification_Custom_Evt_Opcode */
    case CUSTOM_CONN_HANDLE_EVT :
      /* USER CODE BEGIN CUSTOM_CONN_HANDLE_EVT */
        HAL_GPIO_WritePin(LD1_GPIO_Port, LD1_Pin, ON);
      /* USER CODE END CUSTOM_CONN_HANDLE_EVT */
      break;

    case CUSTOM_DISCON_HANDLE_EVT :
      /* USER CODE BEGIN CUSTOM_DISCON_HANDLE_EVT */
    	HAL_GPIO_WritePin(LD1_GPIO_Port, LD1_Pin, OFF);
      /* USER CODE END CUSTOM_DISCON_HANDLE_EVT */
      break;

    default:
      /* USER CODE BEGIN CUSTOM_APP_Notification_default */

      /* USER CODE END CUSTOM_APP_Notification_default */
      break;
  }

  /* USER CODE BEGIN CUSTOM_APP_Notification_2 */

  /* USER CODE END CUSTOM_APP_Notification_2 */

  return;
}

void Custom_APP_Init(void)
{
  /* USER CODE BEGIN CUSTOM_APP_Init */
	UTIL_SEQ_RegTask(1 << CFG_TASK_SEND_TAG_APP_DATA_ID, UTIL_SEQ_RFU, send_tag_app_data);
	Custom_App_Context.Loc_xy_Notification_Status = 0;

	HW_TS_Create(CFG_TIM_PROC_ID_ISR,&tag_app_timer_id, hw_ts_Repeated,send_tag_app_data_callback);
	HW_TS_Start(tag_app_timer_id,TIME_STEP_MS);

	tag_app_init();
  /* USER CODE END CUSTOM_APP_Init */
  return;
}

/* USER CODE BEGIN FD */

//void tag_app(void)
//{
//	NotifyCharData[9]+=1;
//	Custom_Loc_xy_Send_Notification();
//	//UTIL_SEQ_SetTask(1 << CFG_TASK_TAG_APP_ID, CFG_SCH_PRIO_0);
//}
/* USER CODE END FD */

/*************************************************************
 *
 * LOCAL FUNCTIONS
 *
 *************************************************************/

/* My_P2P_Server */
void Custom_Loc_xy_Update_Char(void) /* Property Read */
{
  uint8_t updateflag = 0;

  /* USER CODE BEGIN Loc_xy_UC_1*/

  /* USER CODE END Loc_xy_UC_1*/

  if (updateflag != 0)
  {
    Custom_STM_App_Update_Char(CUSTOM_STM_LOC_XY, (uint8_t *)UpdateCharData);
  }

  /* USER CODE BEGIN Loc_xy_UC_Last*/

  /* USER CODE END Loc_xy_UC_Last*/
  return;
}

void Custom_Loc_xy_Send_Notification(void) /* Property Notification */
{
  uint8_t updateflag = 0;

  /* USER CODE BEGIN Loc_xy_NS_1*/
  if (Custom_App_Context.Loc_xy_Notification_Status == 1)
  {
	  updateflag = 1;
  }
  /* USER CODE END Loc_xy_NS_1*/

  if (updateflag != 0)
  {
    Custom_STM_App_Update_Char(CUSTOM_STM_LOC_XY, (uint8_t *)NotifyCharData);
  }

  /* USER CODE BEGIN Loc_xy_NS_Last*/

  /* USER CODE END Loc_xy_NS_Last*/

  return;
}

/* USER CODE BEGIN FD_LOCAL_FUNCTIONS*/
void send_tag_app_data_callback(void)
{
    UTIL_SEQ_SetTask(1 << CFG_TASK_SEND_TAG_APP_DATA_ID, CFG_SCH_PRIO_0);
}



void send_tag_app_data(void)
{
	tag_app();

	uint16_t x_cm = (uint16_t)(current_location[0] * 100);
	uint16_t y_cm = (uint16_t)(current_location[1] * 100);

	NotifyCharData[1] = (uint8_t)(x_cm & 0xFF);        // x_cm LSB
	NotifyCharData[0] = (uint8_t)((x_cm >> 8) & 0xFF); // x_cm MSB
	NotifyCharData[3] = (uint8_t)(y_cm & 0xFF);        // y_cm LSB
	NotifyCharData[2] = (uint8_t)((y_cm >> 8) & 0xFF); // y_cm MSB

	Custom_Loc_xy_Send_Notification();
}



/* USER CODE END FD_LOCAL_FUNCTIONS*/
